module vcve2_vrf_interface #(
    parameter int unsigned VLEN = 128,
    parameter int unsigned PIPE_WIDTH = 32
) (
    // Clock and Reset
    input   logic                       clk_i,
    input   logic                       rst_ni,

    // Read ports
    input   logic                       req_i,                              // request signal for VRF
    output  logic [PIPE_WIDTH-1:0]      rdata_a_o, rdata_b_o, rdata_c_o,

    // Write port
    input   logic [PIPE_WIDTH-1:0]      wdata_i,

    // Data memory interface
    output logic         data_req_o,
    input  logic         data_gnt_i,
    input  logic         data_rvalid_i,
    input  logic         data_err_i,
    input  logic         data_pmp_err_i,
    output logic         data_we_o,
    output logic [3:0]   data_be_o,
    output logic [31:0]  data_wdata_o,
    input  logic [31:0]  data_rdata_i,
    // LSU control signals
    output logic         data_load_addr_o,  // loads the address for the memory operation in a counter
    input  logic         lsu_gnt_i,         // grant of LSU, if not immediately given for a write we sample the result/operand

    // AGU
    output logic         agu_load_o,
    output logic         agu_get_rs1_o,
    output logic         agu_get_rs2_o,
    output logic         agu_get_rd_o,
    output logic         agu_incr_o,

    // ID signals
    input  logic [3:0]            sel_operation_i,    // each bit enables a different operation, 0 - R RS1, 1 - R RS2, 2 - R RS3, 3 - W RD
    input  logic                  memory_op_i,        // 0 - arithmetic operation, 1 - load/store operation
    input  logic                  unit_stride_i,      // 0 - non-unit stride, 1 - unit stride
    input  logic                  mult_ops_i,      // 0 - non-interleaved, 1 - interleaved
    output logic                  vector_done_o,      // signals the pipeline that the vector operation is finished (most likely with a write to the VRF)
    
    // Slide signals
    input  logic                  slide_op_i,         // 0 - no slide, 1 - slide
    input  logic [31:0]           slide_offset_i,     // offset for the slide operation
    input  logic                  is_slide_up_i,      // 0 - slide down, 1 - slide up

    // LSU signals
    output logic                  lsu_req_o,          // signals the LSU that it can start the memory operation
    input  logic                  lsu_done_i,

    // CSR signals
    input vcve2_pkg::vlmul_e      lmul_i,
    input vcve2_pkg::vsew_e       sew_i,
    input logic [31:0]            vl_i
);

  import vcve2_pkg::*;

  parameter NUM_BYTE_OPS = (VLEN >> ($clog2(PIPE_WIDTH))) << 2; // (VLEN/PIPE_WIDTH) / 8 

  // VRF FSM signals
  vcve2_pkg::vrf_state_t vrf_state, vrf_next_state;
  logic [PIPE_WIDTH-3:0] num_iterations_q, num_iterations_d;
  logic [PIPE_WIDTH-1:0] num_bytes_elements;
  logic [1:0] offset_q, offset_d;
  logic first_iteration_d, first_iteration_q;
  logic last_iteration_d, last_iteration_q;
  logic [3:0] offset_be;
  logic no_offset;

  // Internal registers signals
  logic rs1_en, rs2_en, rs3_en, rd_en;    // rd is used only for load operations
  logic [PIPE_WIDTH-1:0] rs1_q, rs2_q, rs3_q, rd_q;
  logic [PIPE_WIDTH-1:0] rs1_d, rs2_d, rs3_d, rd_d;

  // Delayed grant for read operations in store
  logic read_delayed;
  logic rdata_mux;
  logic write_delayed;
  logic [1:0] curr_state_delay, next_state_delay;
  logic [1:0] wdata_mux;
  logic buffer_en, rd_buf_en;
  logic [PIPE_WIDTH-1:0] buffer_q, buffer_d;

  // Slide instructions support
  logic [23:0] slide_buffer_d, slide_buffer_q;
  logic [31:0] slide_rdata;
  logic slide_buffer_en;
  logic [1:0] slide_offset_q;
  logic slide_offset_en;
  logic slide_first_write_d, slide_first_write_q;
  logic sel_slide_be;                             // signal used to select the correct byte-enable for the first write operation
  logic [3:0] slide_offset_be;
  logic no_offset_first;

  //////////////////
  // BE selector  //
  //////////////////

  // depending on vl we could need to access only a section of the 32 bit word
  always_comb begin
    no_offset = 1'b0;
    no_offset_first = 1'b0;
    // BE for last write
    // For slide down operations it depends both on vl and the offset
    if (slide_op_i && !is_slide_up_i) begin
      case ({offset_q, slide_offset_q})
        4'b0111: begin
          offset_be = 4'b0011;
          no_offset = 1'b1;
        end
        4'b0110, 4'b1011: begin
          offset_be = 4'b0111;
          no_offset = 1'b1;
        end
        4'b0000, 4'b0101, 4'b1010, 4'b1111: begin
          offset_be = 4'b1111;
          no_offset = 1'b1;
        end
        4'b0011, 4'b0100, 4'b1001, 4'b1110: begin
          offset_be = 4'b0001;
        end
        4'b0010, 4'b1000, 4'b1101: begin
          offset_be = 4'b0011;
        end
        4'b0001, 4'b1100: begin
          offset_be = 4'b0111;
        end
        default: offset_be = 4'b0000;
      endcase
    end
    // For other operations it depends only on vl
    else begin
      case (offset_q)
        2'b00: begin
          offset_be = 4'b1111;
          no_offset = 1'b1;
        end
        2'b01: offset_be = 4'b0001;
        2'b10: offset_be = 4'b0011;
        2'b11: offset_be = 4'b0111;
        default: offset_be = 4'b0000;
      endcase
    end
    // In slide up operation the first read can be a different be
    case (slide_offset_q)
      2'b00: begin
        slide_offset_be = 4'b1111;
        no_offset_first = 1'b1;
      end
      2'b01: slide_offset_be = 4'b1110;
      2'b10: slide_offset_be = 4'b1100;
      2'b11: slide_offset_be = 4'b1000;
      default: slide_offset_be = 4'b0000;
    endcase
  end

  always_comb begin
    // if it's the first write of a slideup operation it's possible we need a different byte-enable
    if (sel_slide_be) begin
      if (last_iteration_q) begin
        data_be_o = slide_offset_be & offset_be;
      end
      else data_be_o = slide_offset_be;
    end
    else if (last_iteration_q) begin
      data_be_o = offset_be;
    end
    else begin
      data_be_o = 4'b1111;
    end
  end

  /////////////
  // VRF FSM //
  /////////////

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      vrf_state <= VRF_IDLE;
      num_iterations_q <= '0;
      offset_q <= '0;
      first_iteration_q <= 1'b0;
      last_iteration_q <= 1'b0;
      slide_offset_q <= '0;
      slide_first_write_q <= 1'b0;
    end else begin
      vrf_state <= vrf_next_state;
      num_iterations_q <= num_iterations_d;
      offset_q <= offset_d;
      first_iteration_q <= first_iteration_d;
      last_iteration_q <= last_iteration_d;
      if (slide_offset_en) slide_offset_q <= slide_offset_i[1:0];
      slide_first_write_q <= slide_first_write_d;
    end
  end

  assign num_bytes_elements = vl_i<<sew_i;
  always_comb begin
    // register enables
    rs1_en = 1'b0;
    rs2_en = 1'b0;
    rs3_en = 1'b0;
    rd_en = 1'b0;
    write_delayed = 1'b0;
    read_delayed = 1'b0;
    // data memory interface
    data_req_o = 1'b0;
    data_we_o = 1'b0;
    // agu signals
    agu_load_o = 1'b0;
    agu_get_rs1_o = 1'b0;
    agu_get_rs2_o = 1'b0;
    agu_get_rd_o = 1'b0;
    agu_incr_o = 1'b0;
    // ID signals
    vector_done_o = 1'b0;
    num_iterations_d = num_iterations_q;
    offset_d = offset_q;
    first_iteration_d = first_iteration_q;
    last_iteration_d = last_iteration_q;
    // slide
    slide_buffer_en = 1'b0;
    slide_offset_en = 1'b0;
    slide_first_write_d = slide_first_write_q;
    sel_slide_be = 1'b0;
    // LSU signals
    lsu_req_o = 1'b0;
    data_load_addr_o = 1'b0;

    case (vrf_state)

      VRF_IDLE: begin
        last_iteration_d = 1'b0;
        // VRF stays idle until a request is made
        if (!req_i) begin
          vrf_next_state = VRF_IDLE;
          num_iterations_d = '0;
        // VRF receive a request
        end else begin
          if (vl_i == 0) begin
            vrf_next_state = VRF_IDLE;
            vector_done_o = 1'b1;
            num_iterations_d = '0;
          end else begin
            // AGU - load addresses in the AGU
            agu_load_o = 1'b1;
            // Data memory if - load the start address
            if (memory_op_i) data_load_addr_o = 1'b1;
            num_iterations_d = slide_op_i ? num_bytes_elements[31:2] - slide_offset_i[31:2] : num_bytes_elements[31:2];
            slide_offset_en = slide_op_i;
            offset_d = num_bytes_elements[1:0];
            vrf_next_state = VRF_START;
          end
        end
      end

      VRF_START: begin
        // NEXT STATE SELECTION
        first_iteration_d = 1'b1;
        slide_first_write_d = 1'b1;
        
        if (memory_op_i == 0) begin                   // ARITHMETIC OPERATION
          if (mult_ops_i) begin
            data_req_o = 1'b1;                          // read RS1         
            agu_get_rs1_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_INT_READ1;
            end else vrf_next_state = VRF_START;
            
          end else begin
            if (sel_operation_i[0] || sel_operation_i[1]) begin
              data_req_o = 1'b1;
              if (sel_operation_i[0]) agu_get_rs1_o = 1'b1;
              else agu_get_rs2_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
                if (slide_op_i && !is_slide_up_i && !no_offset_first) vrf_next_state = VRF_LOAD_SLIDE;
                else vrf_next_state = VRF_READ;
              end else vrf_next_state = VRF_START;
            end else if (sel_operation_i[3]) begin
              data_we_o = 1'b1;
              data_req_o = 1'b1;
              agu_get_rd_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
                vrf_next_state = VRF_WRITE;
              end else vrf_next_state = VRF_START;
            end else begin                              // illegal operation  
              vrf_next_state = VRF_IDLE;
            end
          end

        end else begin                                // MEMORY OPERATION
          if (sel_operation_i[2]==1'b1) begin           // store
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_STORE_READ;
            end else vrf_next_state = VRF_START;
          end else if (sel_operation_i[3]==1'b1) begin  // load
            lsu_req_o = 1'b1;
            vrf_next_state = VRF_LOAD;
          end else begin                                // illegal operation
            vrf_next_state = VRF_IDLE;
          end
        end
        
      end

      ////////////////////////////////////////////////
      // Arithmetic operations - binary and ternary //
      ////////////////////////////////////////////////

      // In the following states the exit condition is the gnt signal since: gnt=1 => data_rvalid of the previous operation=1
      VRF_INT_READ1: begin
        // SAMPLE
        if (data_rvalid_i && !last_iteration_q) rs1_en = 1;
        // NEXT STATE SELECTION
        if (!first_iteration_q) begin
          data_we_o = 1'b1;
          data_req_o = 1'b1;
          agu_get_rd_o = 1'b1;
          if (data_gnt_i) begin
            write_delayed = 1'b0;
            agu_incr_o = 1'b1;
            vrf_next_state = VRF_INT_WRITE;
          end else begin
            write_delayed = 1'b1;
            vrf_next_state = VRF_INT_READ1;
          end
        end else begin
          first_iteration_d = 1'b0;
          vrf_next_state = VRF_INT_WRITE;
        end
      end

      VRF_INT_READ2: begin
        // SAMPLE
        if (data_rvalid_i) rs2_en = 1;
        // NEXT STATE SELECTION
        // if next operation is READ RD
        if (sel_operation_i[2]) begin
          data_req_o = 1'b1;
          agu_get_rd_o = 1'b1;
          if (data_gnt_i) begin
            vrf_next_state = VRF_INT_READ3;
          end else vrf_next_state = VRF_INT_READ2;
        // if next operation is WRITE RD
        end else if (sel_operation_i[3]) begin
          if (last_iteration_q) begin
            vrf_next_state = VRF_INT_READ1;
          end else begin
            data_req_o = 1'b1;
            agu_get_rs1_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_INT_READ1;
            end else vrf_next_state = VRF_INT_READ2;
          end
        // illegal operation
        end else begin
          vrf_next_state = VRF_IDLE;
        end
      end
      
      VRF_INT_READ3: begin
        // SAMPLE
        if (data_rvalid_i) rs3_en = 1;
        // NEXT STATE SELECTION
        if (sel_operation_i[3]) begin
          if (last_iteration_q) begin
            vrf_next_state = VRF_INT_READ1;
          end else begin
            data_req_o = 1'b1;
            agu_get_rs1_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_INT_READ1;
            end else vrf_next_state = VRF_INT_READ3;
          end
        // illegal operation
        end else begin
          vrf_next_state = VRF_IDLE;
        end
      end

      VRF_INT_WRITE: begin
        // NEXT STATE SELECTION - moving to the next iteration
        if (last_iteration_q) begin            // it's equal zero to take into account the first iteration
          vector_done_o = 1'b1;
          num_iterations_d = '0;
          vrf_next_state = VRF_IDLE;
        end else begin
          // if next operation is READ RS2
          if (sel_operation_i[1]) begin
            data_req_o = 1'b1;
            agu_get_rs2_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              if (num_iterations_q == (no_offset ? 1 : 0)) last_iteration_d = 1'b1;
              else num_iterations_d = num_iterations_q - 1;
              vrf_next_state = VRF_INT_READ2;
            end else begin
              num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
              vrf_next_state = VRF_INT_WRITE;
            end
          // illegal operation, go back to idle
          end else begin
            vrf_next_state = VRF_IDLE;
          end
        end
      end

      /////////////////////////////////////////////////////////
      // Arithmetic operations - single operand, slide, move //
      /////////////////////////////////////////////////////////

      VRF_LOAD_SLIDE: begin
        if (data_rvalid_i) begin
          rs2_en = 1'b1;
          slide_buffer_en = 1'b1;
        end
        data_req_o = 1'b1;
        agu_get_rs2_o = 1'b1;
        if (data_gnt_i) begin
          agu_incr_o = 1'b1;
          vrf_next_state = VRF_READ;
        end else begin
          vrf_next_state = VRF_LOAD_SLIDE;
        end
      end

      VRF_READ: begin
        // SAMPLE
        if (data_rvalid_i && !last_iteration_q) begin
          rs2_en = 1'b1;
          if (slide_op_i) slide_buffer_en = 1'b1;
        end
        // NEXT STATE SELECTION
        if (!first_iteration_q) begin
          data_we_o = 1'b1;
          data_req_o = 1'b1;
          agu_get_rd_o = 1'b1;
          if (slide_first_write_q && is_slide_up_i) sel_slide_be = 1'b1;
          if (data_gnt_i) begin
            write_delayed = 1'b0;
            agu_incr_o = 1'b1;
            slide_first_write_d = 1'b0;
            vrf_next_state = VRF_WRITE;
          end else begin
            write_delayed = 1'b1;
            vrf_next_state = VRF_READ;
          end
        end else begin
          first_iteration_d = 1'b0;
          vrf_next_state = VRF_WRITE;
        end
      end

      VRF_WRITE: begin
        // NEXT STATE SELECTION - moving to the next iteration
        if (last_iteration_q) begin            // it's equal zero to take into account the first iteration
          vector_done_o = 1'b1;
          num_iterations_d = '0;
          vrf_next_state = VRF_IDLE;
        end else begin
          // if next operation is READ
          if (sel_operation_i[0] || sel_operation_i[1]) begin
            if (num_iterations_q == (no_offset ? 1 : 0)) begin
              last_iteration_d = 1'b1;
              data_req_o = 1'b0;
              vrf_next_state = VRF_READ;
            end
            else begin 
              data_req_o = 1'b1;
              if (sel_operation_i[0]) agu_get_rs1_o = 1'b1;
              else agu_get_rs2_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
                num_iterations_d = num_iterations_q - 1;
                vrf_next_state = VRF_READ;
              end else begin
                num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
                vrf_next_state = VRF_WRITE;
              end
            end
          // if we don't read vs2 it means we write again
          end else begin
            vrf_next_state = VRF_WRITE;
            data_we_o = 1'b1;
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              if (num_iterations_q == (no_offset ? 1 : 0)) last_iteration_d = 1'b1;
              else num_iterations_d = num_iterations_q - 1;
            end else begin
              num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
            end
          end
        end
      end

      ////////////////
      // Load/Store //
      ////////////////

      VRF_LOAD: begin
        if (lsu_done_i || last_iteration_q) begin
          // we sample only if it's not the last iteration
          if (lsu_done_i) rd_en = 1'b1;
          // we send a write request only if it's not the first iteration
          if (!first_iteration_q) begin
            data_we_o = 1'b1;
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_LOAD_WRITE;
            end else begin
              write_delayed = 1'b1;
              vrf_next_state = VRF_LOAD_WAITGNT;
            end
          // if it's the first iteration we don't need to write the result
          end else begin
              first_iteration_d = 1'b0;
              vrf_next_state = VRF_LOAD_WRITE;
          end
        // we wait here for lsu to finish
        end else begin
          vrf_next_state = VRF_LOAD;
        end
      end

      // state where we wait for the grant from memory
      VRF_LOAD_WAITGNT: begin
        data_we_o = 1'b1;
        data_req_o = 1'b1;
        agu_get_rd_o = 1'b1;
        if (data_gnt_i) begin
          write_delayed = 1'b0;
          agu_incr_o = 1'b1;
          vrf_next_state = VRF_LOAD_WRITE;
        end else begin
          vrf_next_state = VRF_LOAD_WAITGNT;
        end
      end

      VRF_LOAD_WRITE: begin
        // if this is the last iteration we finish
        if (last_iteration_q) begin
          vector_done_o = 1'b1;
          num_iterations_d = '0;
          vrf_next_state = VRF_IDLE;
        // if the next iteration will be the last we don't need to read the operand
        end else if (num_iterations_q == (no_offset ? 1 : 0)) begin
          last_iteration_d = 1'b1;
          vrf_next_state = VRF_LOAD;
        // normal operation
        end else begin
          num_iterations_d = num_iterations_q - 1;
          lsu_req_o = 1'b1;
          vrf_next_state = VRF_LOAD;
        end
      end

      VRF_STORE_READ: begin
        // as soon as we see the value on the bus we sample it and tell the lsu it can proceed
        if (data_rvalid_i || last_iteration_q) begin
          if (data_rvalid_i) rs3_en = 1;
          if (!first_iteration_q) begin
            lsu_req_o = 1;
            if (!lsu_gnt_i) read_delayed = 1'b1;
          end
          vrf_next_state = VRF_STORE_WAITLSU;
        end else begin
          vrf_next_state = VRF_STORE_READ;
        end
      end

      VRF_STORE_WAITLSU: begin
        if (lsu_done_i || first_iteration_q) begin
          first_iteration_d = 1'b0;
          read_delayed = 1'b0;
          // Exit condition
          if (last_iteration_q) begin
            vector_done_o = 1'b1;
            num_iterations_d = '0;
            vrf_next_state = VRF_IDLE;
          // In the last cycle we don't read the operand
          end else if (num_iterations_q == (no_offset ? 1 : 0)) begin
            last_iteration_d = 1'b1;
            vrf_next_state = VRF_STORE_READ;
          // Send read request to memory
          end else begin
            num_iterations_d = num_iterations_q - 1;
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_STORE_READ;
            end else begin
              vrf_next_state = VRF_STORE_WAITGNT;
            end
          end
        // we wait in this state
        end else begin
          vrf_next_state = VRF_STORE_WAITLSU;
        end
      end

      VRF_STORE_WAITGNT: begin
        data_req_o = 1'b1;
        agu_get_rd_o = 1'b1;
        if (data_gnt_i) begin
          agu_incr_o = 1'b1;
          vrf_next_state = VRF_STORE_READ;
        end else begin
          vrf_next_state = VRF_STORE_WAITGNT;
        end
      end

      // illegal state go back to idle
      default: begin
        vrf_next_state = VRF_IDLE;
      end
    endcase
  end

  ////////////////////////////////
  // Slide instructions support //
  ////////////////////////////////
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      slide_buffer_q <= '0;
    end else begin
      if (slide_buffer_en) slide_buffer_q <= slide_buffer_d;
    end
  end
  // Since the sampled offset bits are already shifted of SEW bits we can directly use them
  always_comb begin
    slide_buffer_d = slide_buffer_q;
    case (slide_offset_q)
      2'b01: begin
        slide_rdata = is_slide_up_i ? {data_rdata_i[23:0], slide_buffer_q[7:0]} : {data_rdata_i[7:0], slide_buffer_q[23:0]};
        slide_buffer_d = is_slide_up_i ? {16'h0, data_rdata_i[31:24]} : data_rdata_i[31:8];
      end
      2'b10: begin
        slide_rdata = {data_rdata_i[15:0], slide_buffer_q[15:0]};
        slide_buffer_d = {8'h00, data_rdata_i[31:16]};
      end
      2'b11: begin
        slide_rdata = is_slide_up_i ? {data_rdata_i[7:0], slide_buffer_q[23:0]} : {data_rdata_i[23:0], slide_buffer_q[7:0]};
        slide_buffer_d = is_slide_up_i ? data_rdata_i[31:8] : {16'h0, data_rdata_i[31:24]};
      end
      default: slide_rdata = data_rdata_i;
    endcase
  end

  ///////////////////////////
  // Delayed grant support //
  ///////////////////////////

  // Delayed write buffer
  assign buffer_d = read_delayed ? rs3_q : rd_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      curr_state_delay <= 2'b00;
      buffer_q <= '0;
    end else begin
      curr_state_delay <= next_state_delay;
      if (buffer_en) buffer_q <= buffer_d;
    end
  end
  always_comb begin
    rd_buf_en = 1'b0;
    buffer_en = 1'b0;
    rdata_mux = 1'b0;
    wdata_mux = memory_op_i ? 2'b01 : 2'b00;
    case (curr_state_delay)
      // Initial state: we wait for delay
      2'b00: begin
        if (write_delayed || read_delayed) begin
          if (!memory_op_i) rd_buf_en = 1'b1;          // if it's not a memory operation we need to sample input signal
          else buffer_en = 1'b1;                       // if it's a memory operations we : load - sample the already sampled result, store - sample the operand to avoid changing LSU inputs while we wait
          next_state_delay = write_delayed ? 2'b01 : 2'b10;
        end else begin
          next_state_delay = 2'b00;
        end
      end
      // State with write delayed
      2'b01: begin
        wdata_mux = memory_op_i ? 2'b10 : 2'b01;
        if (write_delayed) begin
          next_state_delay = 2'b01;
        end else begin
          next_state_delay = 2'b00;
        end
      end
      // State with read delayed
      2'b10: begin
        rdata_mux = 1'b1;
        if (read_delayed) begin
          next_state_delay = 2'b10;
        end else begin
          next_state_delay = 2'b00;
        end
      end
      default: begin
        next_state_delay = 2'b00;
      end
    endcase
  end

  ////////////////////////
  // Internal registers //
  ////////////////////////

  // Operands and result registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rs1_q <= '0;
      rs2_q <= '0;
      rs3_q <= '0;
      rd_q  <= '0;
    end else begin
      if (rs1_en) rs1_q <= rs1_d;
      if (rs2_en) rs2_q <= rs2_d;
      if (rs3_en) rs3_q <= rs3_d;
      if (rd_en || rd_buf_en) rd_q <= rd_d;
    end
  end
  always_comb begin
    rs1_d = data_rdata_i;
    rs2_d = slide_op_i ? slide_rdata : data_rdata_i;
    rs3_d = data_rdata_i;
    rd_d = wdata_i;
  end

  /////////////
  // Outputs //
  /////////////

  assign rdata_a_o = rs1_q;
  assign rdata_b_o = rs2_q;
  assign rdata_c_o = rdata_mux ? buffer_q : rs3_q;
  // mux for the write data
  always_comb begin
    case (wdata_mux)
      2'b00: data_wdata_o = wdata_i;
      2'b01: data_wdata_o = rd_q;
      2'b10: data_wdata_o = buffer_q;
      default: data_wdata_o = '0;
    endcase
  end

endmodule
