module vcve2_vrf_interface #(
    parameter int unsigned VLEN = 128,
    parameter int unsigned PIPE_WIDTH = 32,
    parameter int unsigned AddrWidth = 5
) (
    // Clock and Reset
    input   logic                 clk_i,
    input   logic                 rst_ni,

    // Read ports
    input   logic                 req_i,     // maybe I could remove it and use num_operands_i instead (when != 0 request), also rigth now it's not needed fot it to stay high should I change?
    input   logic                 we_i,
    input   logic [AddrWidth-1:0] raddr_a_i, raddr_b_i,
    output  logic [PIPE_WIDTH-1:0]      rdata_a_o, rdata_b_o, rdata_c_o, // TO CHANGE THE WIDTH

    // Write port
    input   logic [AddrWidth-1:0] waddr_i,
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
    output logic         mux_data_if_o,     // 1 - driven by VRF, 0 - driven by LSU
    output logic         data_load_addr_o,

    // AGU
    output logic         agu_load_o,
    output logic         agu_get_rs1_o,
    output logic         agu_get_rs2_o,
    output logic         agu_get_rd_o,
    output logic         agu_incr_o,
    input  logic         agu_ready_i, 

    // Control signals and values
    input  logic [3:0]            sel_operation_i,    // each bit enables a different operation, 0 - R RS1, 1 - R RS2, 2 - R RS3, 3 - W RD
    input  logic                  memory_op_i,        // 0 - arithmetic operation, 1 - load/store operation
    output logic                  vector_done_o,      // signals the pipeline that the vector operation is finished (most likely with a write to the VRF)
    output logic                  lsu_req_o,          // signals the LSU that it can start the memory operation
    input  logic                  lsu_done_i,
    input vcve2_pkg::vlmul_e      lmul_i
);

  import vcve2_pkg::*;

  // TODO - find a better way to do this
  parameter NUM_MEM_OPS = VLEN >> ($clog2(PIPE_WIDTH)); // VLEN/PIPE_WIDTH

  // VRF FSM signals
  vcve2_pkg::vrf_state_t vrf_state, vrf_next_state;
  logic [PIPE_WIDTH-1:0] num_iterations_q, num_iterations_d;

  // Internal registers signals
  logic rs1_en, rs2_en, rs3_en;
  logic [PIPE_WIDTH-1:0] rs1_q, rs2_q, rs3_q;

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
    end else begin
      vrf_state <= vrf_next_state;
      num_iterations_q <= num_iterations_d;
    end
  end

  always_comb begin
    rs1_en = 1'b0;
    rs2_en = 1'b0;
    rs3_en = 1'b0;
    data_req_o = 1'b0;
    data_we_o = 1'b0;
    agu_load_o = 1'b0;
    agu_get_rs1_o = 1'b0;
    agu_get_rs2_o = 1'b0;
    agu_get_rd_o = 1'b0;
    agu_incr_o = 1'b0;
    vector_done_o = 1'b0;
    num_iterations_d = num_iterations_q;
    lsu_req_o = 1'b0;
    mux_data_if_o = 1'b0;
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
          data_load_addr_o = 1'b1;
          // ITERATIONS COUNTER - we sample the correct value of num_iterations
          if ($signed(lmul_i) < 0) begin
            num_iterations_d = NUM_MEM_OPS >> -$signed(lmul_i);
          end else begin
            num_iterations_d = NUM_MEM_OPS << $signed(lmul_i);
          end
          vrf_next_state = VRF_WAITAGU;
        end
      end

      VRF_WAITAGU: begin
        if (!agu_ready_i) begin
          vrf_next_state = VRF_WAITAGU;
        end else begin
          vrf_next_state = VRF_START;
        end
      end

      VRF_START: begin
        // NEXT STATE SELECTION
        // ARITHMETIC OPERATION
        if (memory_op_i == 0) begin
          // if the first operation is READ RS1
          if (sel_operation_i[0]) begin
            data_req_o = 1'b1;
            agu_get_rs1_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_READ1;
            end else vrf_next_state = VRF_START;
          // if the first operation is READ RS2
          end else if (sel_operation_i[1]) begin
            data_req_o = 1'b1;
            agu_get_rs2_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_READ2;
            end else vrf_next_state = VRF_START;
          // if the first operation is READ RS3
          end else if (sel_operation_i[2]) begin
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_READ3;
            end else vrf_next_state = VRF_START;
          // if the first operation is WRITE RD
          end else if (sel_operation_i[3]) begin
            data_we_o = 1'b1;
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_WRITE;
            end else vrf_next_state = VRF_START;
          end else begin
            vrf_next_state = VRF_IDLE;
          end

        // MEMORY OPERATION
        end else begin
          // if it's a STORE
          if (sel_operation_i[2]==1'b1) begin
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_STORE1;
            end else vrf_next_state = VRF_START;
          // if it's a LOAD
          end else if (sel_operation_i[3]==1'b1) begin
            lsu_req_o = 1'b1;
            mux_data_if_o = 1'b1;
            vrf_next_state = VRF_LOAD1;
          // invalid
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
        // if next operation is READ RD
        if (sel_operation_i[2]) begin   // read third operand
          data_req_o = 1'b1;
          agu_get_rd_o = 1'b1;
          if (data_gnt_i) begin
            agu_incr_o = 1'b1;
            vrf_next_state = VRF_READ3;
          end else vrf_next_state = VRF_READ2;
        // if next operation is WRITE RD
        end else if (sel_operation_i[3]) begin  // write result
          vrf_next_state = VRF_WAITBUS;
        end else begin     // if we move to the next element
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
      
      VRF_READ3: begin
        // SAMPLE
        if (data_rvalid_i) rs3_en = 1;
        // NEXT STATE SELECTION
        if (sel_operation_i[3]) begin
          vrf_next_state = VRF_WAITBUS;
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
                vrf_next_state = VRF_READ3;
              end
            // if next operation is READ RD
            end else if (sel_operation_i[2]) begin
              data_req_o = 1'b1;
              agu_get_rd_o = 1'b1;
              if (data_gnt_i) begin
                agu_incr_o = 1'b1;
              end else begin
                num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
              end
              vrf_next_state = VRF_READ3;
            end else begin
              vrf_next_state = VRF_IDLE;
            end
          end
        end
      end

      // state needed to wait for the bus to be ready to write
      VRF_WAITBUS: begin
        data_we_o = 1'b1;
        data_req_o = 1'b1;
        agu_get_rd_o = 1'b1;
        if (data_gnt_i) begin
          agu_incr_o = 1'b1;
          vrf_next_state = VRF_WRITE;
        end else begin
          vrf_next_state = VRF_WAITBUS;
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
          // if next operation is READ RS1
          if (sel_operation_i[0]) begin
            data_req_o = 1'b1;
            agu_get_rs1_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_READ1;
            end else begin
              num_iterations_d = num_iterations_q;   // if the operation wasn't accepted we need to repeat it
              vrf_next_state = VRF_WRITE;
            end
          // if next operation is READ RD
          end else if (sel_operation_i[2]) begin
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_READ3;
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
          // illegal operation, go back to idle
          end else begin
            vrf_next_state = VRF_IDLE;
          end
        end
      end

      ////////////////
      // Load/Store //
      ////////////////

      VRF_LOAD1: begin
        if (lsu_done_i) begin
          data_we_o = 1'b1;
          data_req_o = 1'b1;
          agu_get_rd_o = 1'b1;
          if (data_gnt_i) begin
            agu_incr_o = 1'b1;
            vrf_next_state = VRF_LOAD3;
          end else begin
            vrf_next_state = VRF_LOAD2;
          end
        end else begin
          mux_data_if_o = 1'b1;
          vrf_next_state = VRF_LOAD1;
        end
      end

      VRF_LOAD2: begin
        data_we_o = 1'b1;
        data_req_o = 1'b1;
        agu_get_rd_o = 1'b1;
        if (data_gnt_i) begin
          agu_incr_o = 1'b1;
          vrf_next_state = VRF_LOAD3;
        end else begin
          vrf_next_state = VRF_LOAD2;
        end
      end

      VRF_LOAD3: begin
        if (num_iterations_q == 1) begin
          vector_done_o = 1'b1;
          num_iterations_d = '0;
          vrf_next_state = VRF_IDLE;
        end else begin
          num_iterations_d = num_iterations_q - 1;
          lsu_req_o = 1'b1;
          mux_data_if_o = 1'b1;
          vrf_next_state = VRF_LOAD1;
        end
      end

      VRF_STORE1: begin
        // as soon as we see the value on the bus we sample it and tell the lsu it can proceed
        if (data_rvalid_i) begin
          rs3_en = 1;
          lsu_req_o = 1;
          mux_data_if_o = 1'b1;
          vrf_next_state = VRF_STORE2;
        end else begin
          vrf_next_state = VRF_STORE1;
        end
      end

      // I could save one cycle by anticipating the memory request in this stage
      VRF_STORE2: begin
        if (lsu_done_i) begin
          if (num_iterations_q == 1) begin
            vector_done_o = 1'b1;
            num_iterations_d = '0;
            vrf_next_state = VRF_IDLE;
          end else begin
            num_iterations_d = num_iterations_q - 1;
            data_req_o = 1'b1;
            agu_get_rd_o = 1'b1;
            if (data_gnt_i) begin
              agu_incr_o = 1'b1;
              vrf_next_state = VRF_STORE1;
            end else begin
              vrf_next_state = VRF_STORE3;
            end
          end
        end else begin
          mux_data_if_o = 1'b1;
          vrf_next_state = VRF_STORE2;
        end
      end

      VRF_STORE3: begin
        data_req_o = 1'b1;
        agu_get_rd_o = 1'b1;
        if (data_gnt_i) begin
          agu_incr_o = 1'b1;
          vrf_next_state = VRF_STORE1;
        end else begin
          vrf_next_state = VRF_STORE2;
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

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rs1_q <= '0;
      rs2_q <= '0;
      rs3_q <= '0;
    end else begin
      // source registers can be loaded in parallel and shifted left by 32
      if (rs1_en) rs1_q <= data_rdata_i;
      if (rs2_en) rs2_q <= data_rdata_i;
      if (rs3_en) rs3_q <= data_rdata_i;
    end
  end

  assign rdata_a_o = rs1_q;
  assign rdata_b_o = rs2_q;
  assign rdata_c_o = rs3_q;

endmodule
