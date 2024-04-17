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

    // AGU
    output logic         agu_load_o,
    output logic         agu_get_rs1_o,
    output logic         agu_get_rs2_o,
    output logic         agu_get_rd_o,
    input  logic         agu_ready_i, 

    // Control signals and values
    input logic [1:0]             num_operands_i,             // I was thinking of changing it to 3 bits, each one of them representing a source register
    output  logic                 vector_done_o,              // signals the pipeline that the vector operation is finished (most likely with a write to the VRF)
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
  logic [VLEN-1:0] rs1_q, rs2_q, rs3_q;

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

    case (vrf_state)

      VRF_IDLE: begin
        if (!req_i) begin             // VRF stays idle until a request is made
          vrf_next_state = VRF_IDLE;
          num_iterations_d = '0;
        end else begin                // when we have a request
          vrf_next_state = VRF_START;
          // load addresses in the AGU
          agu_load_o = 1'b1;
          // we sample the correct value of num_iterations
          case (lmul_i)
            VLMUL_F8: begin
              num_iterations_d = COUNT>>3;
            end
            VLMUL_F4: begin
              num_iterations_d = COUNT>>2;
            end
            VLMUL_F2: begin
              num_iterations_d = COUNT>>1;
            end
            VLMUL_1: begin
              num_iterations_d = COUNT;
            end
            VLMUL_2: begin
              num_iterations_d = COUNT<<1;
            end
            VLMUL_4: begin
              num_iterations_d = COUNT<<2;
            end
            VLMUL_8: begin
              num_iterations_d = COUNT<<3;
            end
            default: begin
              num_iterations_d = '0;
            end
          endcase

        end
      end

      VRF_START: begin
        if (agu_ready_i) begin
          vrf_next_state = VRF_OP;
          /* RAM READ REQUEST */
          vrf_next_state = VRF_READ1;
        end else begin
          vrf_next_state = VRF_START;    
        end
      end

      VRF_READ1: begin
        rs1_en = 1;
        /* RAM READ REQUEST */
        vrf_next_state = VRF_READ2;
      end

      VRF_READ2: begin
        rs2_en = 1;
        /* RAM READ REQUEST */
        vrf_next_state = VRF_READ3;
      end
      
      VRF_READ3: begin
        rs3_en = 1;
        vrf_next_state = VRF_LOOP;
      end

      VRF_LOOP: begin
        if (num_iterations_q == '0) begin
          vrf_next_state = VRF_IDLE;
        end else begin
          num_iterations_d = num_iterations_q - 1;
          /* RAM READ REQUEST */
          vrf_next_state = VRF_READ1;
        end
      end

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

endmodule
