module vregfile_wrapper #(
    parameter int unsigned DataWidth = 128,
    parameter int unsigned AddrWidth = 5
) (
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    // Read and write port
    input  logic                 req_i,     // maybe I could remove it and use num_operands_i instead (when != 0 request), also rigth now it's not needed fot it to stay high should I change?
    input logic we_i,
    input logic [AddrWidth-1:0] raddr_1_i, raddr_2_i, raddr_3_i,
    input logic [DataWidth-1:0] wdata_i,
    output logic [DataWidth-1:0] rdata_1_o, rdata_2_o, rdata_3_o

    // VRF related FSM signals
    // input logic [1:0] num_operands_i

    // Pipeline related FSM signals
    /* Still nothing but probably I will need them */
);

  typedef enum {
    VRF_IDLE,
    VRF_READ1,
    VRF_READ2,
    VRF_READ3,
    V_OP,
    VRF_WRITE
  } vrf_state_t;

  // RAM interface
  logic req_s, we_s;
  logic [AddrWidth-1:0] addr_s;
  logic [DataWidth-1:0] rdata_s;

  // VRF FSM signals
  vrf_state_t vrf_state, vrf_next_state;

  // Internal registers signals
  logic rs1_en, rs2_en, rs3_en, rd_en;
  logic [DataWidth-1:0] rs1_q, rs2_q, rs3_q;
  logic [DataWidth-1:0] rd_q;

  // Output signals
  assign rdata_1_o = rs1_q;
  assign rdata_2_o = rs2_q;
  assign rdata_3_o = rs3_q;
  assign rd_en = 0;

  /////////////
  // VRF FSM //
  /////////////

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      vrf_state <= VRF_IDLE;
    end else begin
      vrf_state <= vrf_next_state;
    end
  end

  always_comb begin
    rs1_en = 0;
    rs2_en = 0;
    rs3_en = 0;
    case (vrf_state)
      VRF_IDLE: begin
        if (!req_i) begin
          vrf_next_state = VRF_IDLE;
        end else begin
          // RAM read request
          req_s = 1;
          we_s = 0;
          addr_s = raddr_1_i;
          vrf_next_state = VRF_READ1;
        end
      end
      VRF_READ1: begin
        // RAM read request
        req_s = 1;
        we_s = 0;
        addr_s = raddr_2_i;
        rs1_en = 1;
        vrf_next_state = VRF_READ2;
      end
      VRF_READ2: begin
        // RAM read request
        req_s = 1;
        we_s = 0;
        addr_s = raddr_3_i;
        rs2_en = 1;
        vrf_next_state = VRF_READ3;
      end
      VRF_READ3: begin
        rs3_en = 1;
        vrf_next_state = V_OP;
      end
      V_OP: begin
        vrf_next_state = VRF_WRITE;
      end
      VRF_WRITE: begin
        vrf_next_state = VRF_IDLE;
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
      rd_q  <= '0;
    end else begin
      if (rs1_en) rs1_q <= rdata_s;
      if (rs2_en) rs2_q <= rdata_s;
      if (rs3_en) rs3_q <= rdata_s;
      if (rd_en) rd_q <= wdata_i;
    end
  end

  /////////
  // VRF //
  /////////

  // Instantiate prim_generic_ram_1p
  ram_1p #(
      .Width(DataWidth),
      .Depth(2 ** AddrWidth)
  ) ram_inst (
      .clk_i(clk_i),
      .req_i(req_s),
      .we_i(we_s),
      .addr_i(addr_s),
      .wdata_i(wdata_i),
      .rdata_o(rdata_s)
  );

endmodule
