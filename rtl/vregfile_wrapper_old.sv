module vcve2_vrf_interface #(
    parameter int unsigned VLEN = 128,
    parameter int unsigned ELEN = 32,
    parameter int unsigned AddrWidth = 5
) (
    // Clock and Reset
    input   logic                 clk_i,
    input   logic                 rst_ni,

    // Read ports
    input   logic                 req_i,     // maybe I could remove it and use num_operands_i instead (when != 0 request), also rigth now it's not needed fot it to stay high should I change?
    input   logic                 we_i,
    input   logic [AddrWidth-1:0] raddr_a_i, raddr_b_i,
    output  logic [ELEN-1:0]      rdata_a_o, rdata_b_o, rdata_c_o, // TO CHANGE THE WIDTH

    // Write port
    input   logic [AddrWidth-1:0] waddr_i,
    input   logic [ELEN-1:0]      wdata_i,

    // Control signals and values
    input logic [1:0]             num_operands_i,
    output  logic                 vector_done_o,              // signals the pipeline that the vector operation is finished (most likely with a write to the VRF)
    input vcve2_pkg::vlmul_e      lmul_i
);

  import vcve2_pkg::*;

  parameter COUNT = VLEN/ELEN;

  // RAM interface
  logic req_s, we_s;
  logic [AddrWidth-1:0] addr_s;
  logic [VLEN-1:0] rdata_s;

  // VRF FSM signals
  vcve2_pkg::vrf_state_t vrf_state, vrf_next_state;
  logic [9:0] count_valid_d, count_valid_q, count_d, count_q;         // number of shift to do (changes with fractional LMUL)
  logic [2:0] num_regs_d, num_regs_q;   // number of regs in the register group
  logic [AddrWidth-1:0] incr_d, incr_q;

  // Internal registers signals
  logic rs1_en, rs2_en, rs3_en, rs1_shift, rs2_shift, rs3_shift, rd_shift;
  logic [VLEN-1:0] rs1_q, rs2_q, rs3_q;
  logic [VLEN-1:0] rd_q;
  logic stop_shift;

  // Output signals - first positions first to support propery fractional LMUL/EMUL
  assign rdata_a_o = stop_shift ? '0 : rs1_q[ELEN-1:0];
  assign rdata_b_o = stop_shift ? '0 : rs2_q[ELEN-1:0];
  assign rdata_c_o = stop_shift ? '0 : rs3_q[ELEN-1:0];

  /////////////
  // VRF FSM //
  /////////////

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      vrf_state <= VRF_IDLE;
      count_valid_q <= 0;
      count_q <= 0;
      num_regs_q <= 0;
      incr_q <= 0;
    end else begin
      vrf_state <= vrf_next_state;
      count_valid_q <= count_valid_d;
      count_q <= count_d;
      num_regs_q <= num_regs_d;
      incr_q <= incr_d;
    end
  end

  always_comb begin
    rs1_en = 0;
    rs2_en = 0;
    rs3_en = 0;
    rs1_shift = 0;
    rs2_shift = 0;
    rs3_shift = 0;
    rd_shift = 0;
    vector_done_o = 0;
    req_s = 0;
    we_s = 0;
    stop_shift = 0;
    case (vrf_state)

      VRF_IDLE: begin
        if (!req_i) begin   // VRF stays idle until a request is made
          vrf_next_state = VRF_IDLE;
          incr_d = '0;
        end else begin      // when there's a request sample count and num_regs

          count_d = COUNT[9:0];
          count_valid_d = COUNT[9:0];
          if (incr_q=='0) begin // if it's the first time I sample the LMUL
            case (lmul_i)
              VLMUL_F8: begin
                count_valid_d = COUNT[9:0]>>3;
                num_regs_d = 3'b000;
              end
              VLMUL_F4: begin
                count_valid_d = COUNT[9:0]>>2;
                num_regs_d = 3'b000;
              end
              VLMUL_F2: begin
                count_valid_d = COUNT[9:0]>>1;
                num_regs_d = 3'b000;
              end
              VLMUL_1: begin
                count_valid_d = COUNT[9:0];
                num_regs_d = 3'b000;
              end
              VLMUL_2: begin
                count_valid_d = COUNT[9:0];
                num_regs_d = 3'b001;
              end
              VLMUL_4: begin
                count_valid_d = COUNT[9:0];
                num_regs_d = 3'b011;
              end
              VLMUL_8: begin
                count_valid_d = COUNT[9:0];
                num_regs_d = 3'b111;
              end
              default: begin
                count_valid_d = '0;
                num_regs_d = '0;
              end
            endcase
          end 

          if (num_operands_i==2'b00) begin  // if I have no operands don't need to read
            vrf_next_state = V_OP;
          end else begin                    // if I have operands read them
            // RAM read request
            req_s = 1;
            we_s = 0;
            addr_s = raddr_a_i+incr_q;
            vrf_next_state = VRF_READ1;
          end
        end
      end

      VRF_READ1: begin
        rs1_en = 1;
        if (num_operands_i==2'b01) begin
          vrf_next_state = V_OP;
        end else begin
          // RAM read request
          req_s = 1;
          we_s = 0;
          addr_s = raddr_b_i+incr_q;
          vrf_next_state = VRF_READ2;
        end
      end

      VRF_READ2: begin
        rs2_en = 1;
        if (num_operands_i==2'b10) begin
          vrf_next_state = V_OP;
        end else begin
          // RAM read request
          req_s = 1;
          we_s = 0;
          addr_s = waddr_i+incr_q;
          vrf_next_state = VRF_READ3;
        end
      end
      
      VRF_READ3: begin
        rs3_en = 1;
        vrf_next_state = V_OP;
      end

      V_OP: begin
        count_d = count_q-1;                    // counter for overall number of shifts
        if (we_i==1) rd_shift = 1;              // I shift the destination register regardless
        if (count_valid_q==0) begin             // I shift the source registers only when I have to
          stop_shift = 1;
          if (num_operands_i>0) rs1_shift = 1;
          if (num_operands_i>1) rs2_shift = 1;
          if (num_operands_i>2) rs3_shift = 1;
        end else begin                          // decrement in else to avoid useless decrements
          count_valid_d = count_valid_q-1;      // counter for valid number of shifts (the difference with the former is to aligned rd_q)
        end
        if (count_q==1)                         // next state selection
          vrf_next_state = VRF_WRITE;
        else
          vrf_next_state = V_OP;
      end

      VRF_WRITE: begin
        vrf_next_state = VRF_IDLE;
        if (we_i==1) begin
          // RAM write request
          req_s = 1;
          we_s = 1;
          addr_s = waddr_i+incr_q;
        end
        if (num_regs_q==3'b000) begin
          vector_done_o = 1;
          incr_d = '0;
        end else begin
          num_regs_d = num_regs_q-1;
          incr_d = incr_q+1;
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
      rd_q  <= '0;
    end else begin
      // source registers can be loaded in parallel and shifted left by 32
      if (rs1_en) rs1_q <= rdata_s;
      else if (rs1_shift) rs1_q <= {32'h00000000, rs1_q[VLEN-1:ELEN]};
      if (rs2_en) rs2_q <= rdata_s;
      else if (rs2_shift) rs2_q <= {32'h00000000, rs2_q[VLEN-1:ELEN]};
      if (rs3_en) rs3_q <= rdata_s;
      else if (rs3_shift) rs3_q <= {32'h00000000, rs3_q[VLEN-1:ELEN]};
      // destination register can be shifted left to load new data sequentially
      if (rd_shift) rd_q <= {wdata_i, rd_q[VLEN-1:ELEN]};
    end
  end

  /////////
  // VRF //
  /////////

  // Instantiate prim_generic_ram_1p
  ram_1pc #(
      .Width(VLEN),
      .Depth(2 ** AddrWidth)
  ) ram_inst (
      .clk_i(clk_i),
      .req_i(req_s),
      .we_i(we_s),
      .addr_i(addr_s),
      .wdata_i(rd_q),
      .rdata_o(rdata_s)
  );

endmodule