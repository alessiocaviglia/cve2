module vcve2_lsu_interface (
  input  logic        clk_i,
  input  logic        rst_ni,
  // signals to LSU
  output logic [31:0] lsu_addr_o,
  output logic [31:0] lsu_wdata_o,
  output logic        lsu_req_o,
  output logic        en_rvalid_o,
  // signals from LSU
  input  logic        lsu_resp_valid_i,
  input  logic        lsu_gnt_i,
  // signals from ID/EX
  input  logic [31:0] start_addr_i,
  input  logic        load_start_i,
  input  logic        unit_stride_i,
  input  logic        vec_op_i,
  // signals from VRF
  input  logic        vrf_req_i,
  input  logic [31:0] vrf_data_i,
  output logic        vrf_lsu_gnt_o,
  // scalar pipeline signals
  input  logic        scalar_req_i,
  input  logic [31:0] scalar_addr_i,
  input  logic [31:0] scalar_wdata_i
);

  // Address counter with parallel load
  logic [31:0] addr_q, addr_d;
  logic curr_state, next_state; 

  // Used by the VRF to store prevous operand in buffer so that it's not lost
  assign vrf_lsu_gnt_o = vec_op_i ? lsu_gnt_i : 1'b0;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      addr_q <= 0;
      curr_state <= 0;
    end else begin
      addr_q <= addr_d;
      curr_state <= next_state;
    end
  end

  // I don't remember why I added this FSM, I will need to verify its usefulness
  always_comb begin
    next_state = curr_state;
    en_rvalid_o = 0;
    case(curr_state)
      0: begin
        if (vrf_req_i) begin
          next_state = 1;
        end
      end
      1: begin
        en_rvalid_o = 1;
        if (lsu_resp_valid_i) begin
          next_state = 0;
        end
      end
    endcase
  end

  always_comb begin
    addr_d = addr_q;
    // when we start a vector memory op load the start address
    if (load_start_i) begin
      addr_d = start_addr_i;
    // when the previous mem op is finished we increment the address
    end else if(lsu_resp_valid_i) begin
      addr_d = unit_stride_i ? addr_q + 4 : scalar_addr_i;
    end
  end

  ////////////
  // Output //
  ////////////

  // If there's a vector operation the LSU can only be used by the VRF
  assign lsu_addr_o = vec_op_i ? addr_q : scalar_addr_i;
  assign lsu_wdata_o = vec_op_i ? vrf_data_i : scalar_wdata_i;
  assign lsu_req_o = vec_op_i ? vrf_req_i : scalar_req_i;

endmodule
