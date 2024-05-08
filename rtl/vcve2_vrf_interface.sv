module vcve2_vrf_interface #(
    parameter int unsigned VLEN = 128,
    parameter int unsigned PIPE_WIDTH = 32,
    parameter int unsigned AddrWidth = 5
) (
    // Clock and Reset
    input   logic                       clk_i,
    input   logic                       rst_ni,

    // Read ports
    input   logic                       req_i,
    input   logic                       we_i,
    input   logic [AddrWidth-1:0]       raddr_a_i, raddr_b_i,
    output  logic [PIPE_WIDTH-1:0]      rdata_a_o, rdata_b_o, rdata_c_o,

    // Write port
    input   logic [AddrWidth-1:0]       waddr_i,
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
    // control signals
    output logic         data_load_addr_o,

    // AGU
    output logic         agu_load_o,
    output logic         agu_get_rs1_o,
    output logic         agu_get_rs2_o,
    output logic         agu_get_rd_o,
    output logic         agu_incr_o,

    // ID signals
    input  logic [3:0]            sel_operation_i,    // each bit enables a different operation, 0 - R RS1, 1 - R RS2, 2 - R RS3, 3 - W RD
    input  logic                  memory_op_i,        // 0 - arithmetic operation, 1 - load/store operation
    input  logic                  interleaved_i,      // 0 - non-interleaved, 1 - interleaved
    output logic                  vector_done_o,      // signals the pipeline that the vector operation is finished (most likely with a write to the VRF)
    
    // LSU signals
    output logic                  lsu_req_o,          // signals the LSU that it can start the memory operation
    input  logic                  lsu_done_i,

    // CSR signals
    input vcve2_pkg::vlmul_e      lmul_i
);

  import vcve2_pkg::*;

  // TODO - find a better way to do this
  parameter NUM_MEM_OPS = VLEN >> ($clog2(PIPE_WIDTH)); // VLEN/PIPE_WIDTH

  // VRF FSM signals
  vcve2_pkg::vrf_state_t vrf_state, vrf_next_state;
  logic [PIPE_WIDTH-1:0] num_iterations_q, num_iterations_d;
  logic first_iteration_d, first_iteration_q;
  logic last_iteration_d, last_iteration_q;

  // Internal registers signals
  logic rs1_en, rs2_en, rs3_en, rd_en;
  logic [PIPE_WIDTH-1:0] rs1_q, rs2_q, rs3_q, rd_q;
  logic [PIPE_WIDTH-1:0] rs1_d, rs2_d, rs3_d, rd_d;

  ////////////////
  // Temporary  //
  ////////////////

  assign data_be_o = 4'b1111;
  assign data_wdata_o = wdata_i;

  /////////////
  // VRF FSM //
  /////////////

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      vrf_state <= VRF_IDLE;
      num_iterations_q <= '0;
      first_iteration_q <= 1'b0;
      last_iteration_q <= 1'b0;
    end else begin
      vrf_state <= vrf_next_state;
      num_iterations_q <= num_iterations_d;
      first_iteration_q <= first_iteration_d;
      last_iteration_q <= last_iteration_d;
    end
  end

  always_comb begin
    // register enables
    rs1_en = 1'b0;
    rs2_en = 1'b0;
    rs3_en = 1'b0;
    rd_en = 1'b0;
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
    first_iteration_d = first_iteration_q;
    last_iteration_d = last_iteration_q;
    // LSU signals
    lsu_req_o = 1'b0;
    data_load_addr_o = 1'b0;

    case (vrf_state)

      VRF_IDLE: begin
        // VRF stays idle until a request is made
        if (!req_i) begin
          vrf_next_state = VRF_IDLE;
          num_iterations_d = '0;
        // VRF receive a request
        end else begin
          // AGU - load addresses in the AGU
          agu_load_o = 1'b1;
          // Data memory if - load the start address
          if (memory_op_i) data_load_addr_o = 1'b1;
          // ITERATIONS COUNTER - we sample the correct value of num_iterations
          if ($signed(lmul_i) < 0) begin
            num_iterations_d = NUM_MEM_OPS >> -$signed(lmul_i);
          end else begin
            num_iterations_d = NUM_MEM_OPS << $signed(lmul_i);
          end
          vrf_next_state = VRF_START;
        end
      end

      VRF_START: begin
        // NEXT STATE SELECTION
        if (memory_op_i == 0) begin                   // ARITHMETIC OPERATION
          if (interleaved_i) begin                 // OPTIMIZED INTERLEAVED OPS
            first_iteration_d = 1'b1;
            last_iteration_d = 1'b0;
            data_req_o = 1'b1;                          // read RS1         
            agu_get_rs1_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_INT_READ1;
            end else vrf_next_state = VRF_START;
          end else begin                              // UNOPTIMIZED OPS
            if (sel_operation_i[0]) begin               // read RS1
              data_req_o = 1'b1;
              agu_get_rs1_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
                vrf_next_state = VRF_READ1;
              end else vrf_next_state = VRF_START;
            end else if (sel_operation_i[1]) begin      // read RS2
              data_req_o = 1'b1;
              agu_get_rs2_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
                vrf_next_state = VRF_READ2;
              end else vrf_next_state = VRF_START;
            end else if (sel_operation_i[3]) begin      // write RD
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
          first_iteration_d = 1'b1;
          last_iteration_d = 1'b0;
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

      /////////////////////////////////////////
      // Arithmetic operations - interleaved //
      /////////////////////////////////////////

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
            agu_incr_o = 1'b1;
            vrf_next_state = VRF_INT_WRITE;
          end else begin
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
            agu_incr_o = 1'b1;
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
          if (num_iterations_q == 0) begin
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
          num_iterations_d = num_iterations_q - 1;
          // if next operation is READ RS2
          if (sel_operation_i[1]) begin
            data_req_o = 1'b1;
            agu_get_rs2_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              if (num_iterations_q == 1) last_iteration_d = 1'b1;
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

      ///////////////////////////
      // Arithmetic operations //
      ///////////////////////////

      // In the following states the exit condition is the gnt signal since: gnt=1 => data_rvalid of the previous operation=1
      VRF_READ1: begin
        // SAMPLE
        if (data_rvalid_i) rs1_en = 1;
        // NEXT STATE SELECTION
        // from here we can only move to READ RS2
        if (sel_operation_i[1]) begin
          data_req_o = 1'b1;
          agu_get_rs2_o = 1'b1;
          if (data_gnt_i) begin
            agu_incr_o = 1'b1;
            vrf_next_state = VRF_READ2;
          end else vrf_next_state = VRF_READ1;
        end else begin
          vrf_next_state = VRF_IDLE;
        end
      end

      VRF_READ2: begin
        // SAMPLE
        if (data_rvalid_i) rs2_en = 1;
        // NEXT STATE SELECTION
        // if next operation is WRITE RD
        if (sel_operation_i[3]) begin
          data_we_o = 1'b1;
          data_req_o = 1'b1;
          agu_get_rd_o = 1'b1;
          if (data_gnt_i) begin
            agu_incr_o = 1'b1;
            vrf_next_state = VRF_WRITE;
          end else begin
            vrf_next_state = VRF_READ2;
          end
        end else begin
          // NEXT STATE SELECTION - moving to the next iteration
          if (num_iterations_q == 1) begin
            vector_done_o = 1'b1;
            num_iterations_d = '0;
            vrf_next_state = VRF_IDLE;
          end else begin
            num_iterations_d = num_iterations_q - 1;
            // if next operation is READ RS1
            if (sel_operation_i[0]) begin
              data_req_o = 1'b1;
              agu_get_rs1_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
                vrf_next_state = VRF_READ1;
              end else begin
                num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
                vrf_next_state = VRF_READ2;
              end
            end else begin
              vrf_next_state = VRF_IDLE;
            end
          end
        end
      end

      VRF_WRITE: begin
        // NEXT STATE SELECTION - moving to the next iteration
        if (num_iterations_q == 1) begin
          vector_done_o = 1'b1;
          num_iterations_d = '0;
          vrf_next_state = VRF_IDLE;
        end else begin
          num_iterations_d = num_iterations_q - 1;
          // if next operation is READ RS2
          if (sel_operation_i[1]) begin
            data_req_o = 1'b1;
            agu_get_rs2_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_READ2;
            end else begin
              num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
              vrf_next_state = VRF_WRITE;
            end
          // if next operation is WRITE RD
          end else if (sel_operation_i[3]) begin
            data_we_o = 1'b1;
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
            end else begin
              num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
            end
            vrf_next_state = VRF_WRITE;
          end else begin
            vrf_next_state = VRF_IDLE;
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
            end else vrf_next_state = VRF_LOAD_WAITGNT;
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
        end else if (num_iterations_q == 1) begin
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
          if (!first_iteration_q) lsu_req_o = 1;
          vrf_next_state = VRF_STORE_WAITLSU;
        end else begin
          vrf_next_state = VRF_STORE_READ;
        end
      end

      VRF_STORE_WAITLSU: begin
        if (lsu_done_i || first_iteration_q) begin
          // Exit condition
          if (last_iteration_q) begin
            vector_done_o = 1'b1;
            num_iterations_d = '0;
            vrf_next_state = VRF_IDLE;
          // In the last cycle we don't read the operand
          end else if (num_iterations_q == 1) begin
            last_iteration_d = 1'b1;
            vrf_next_state = VRF_STORE_READ;
          // Send read request to memory
          end else begin
            first_iteration_d = 1'b0;
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

  ////////////////////////
  // Internal registers //
  ////////////////////////

  // Operands and result registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rs1_q <= '0;
      rs2_q <= '0;
      rs3_q <= '0;
    end else begin
      if (rs1_en) rs1_q <= rs1_d;
      if (rs2_en) rs2_q <= rs2_d;
      if (rs3_en) rs3_q <= rs3_d;
      if (rd_en) rd_q <= rd_d;
    end
  end
  always_comb begin
    rs1_d = rs1_en ? data_rdata_i : rs1_q;
    rs2_d = rs2_en ? data_rdata_i : rs2_q;
    rs3_d = rs3_en ? data_rdata_i : rs3_q;
    rd_d = rd_en ? wdata_i : rd_q;
  end

  assign rdata_a_o = rs1_q;
  assign rdata_b_o = rs2_q;
  assign rdata_c_o = rs3_q;
  // if the grant is not immediately given after the read we need to use the sampled result
  // assign data_wdata_o = (!data_rvalid_i && data_we_o) ? rs3_q : wdata_i;
  assign data_wdata_o = wdata_i;

endmodule
