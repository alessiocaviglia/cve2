module vcve2_dmem_switch #(
    parameter int unsigned NumIfs = 1
) (
	input  logic                  clk_i,
	input  logic                  rst_ni,
	// Data memory interface
	output logic [NumIfs-1:0]         data_req_o,
  input  logic [NumIfs-1:0]         data_gnt_i,
  input  logic [NumIfs-1:0]         data_rvalid_i,
  output logic [NumIfs-1:0]         data_we_o,
  output logic [NumIfs-1:0] [3:0]   data_be_o,
  output logic [NumIfs-1:0] [31:0]  data_addr_o,
  output logic [NumIfs-1:0] [31:0]  data_wdata_o,
  input  logic [NumIfs-1:0] [31:0]  data_rdata_i,
  input  logic [NumIfs-1:0]         data_err_i,
	// VRF signals
	input  logic [NumIfs-1:0]         vrf_data_req_i,
  output logic [NumIfs-1:0]         vrf_data_gnt_o,
  output logic [NumIfs-1:0]         vrf_data_rvalid_o,
  input  logic [NumIfs-1:0]         vrf_data_we_i,
  input  logic [NumIfs-1:0] [3:0]   vrf_data_be_i,
  input  logic [NumIfs-1:0] [31:0]  vrf_data_addr_i,
  input  logic [NumIfs-1:0] [31:0]  vrf_data_wdata_i,
  output logic [NumIfs-1:0] [31:0]  vrf_data_rdata_o,
  output logic [NumIfs-1:0]         vrf_data_err_o,
  // LSU signals
	input  logic                      lsu_data_req_i,
  output logic                      lsu_data_gnt_o,
  output logic                      lsu_data_rvalid_o,
  input  logic                      lsu_data_we_i,
  input  logic [3:0]                lsu_data_be_i,
  input  logic [31:0]               lsu_data_addr_i,
  input  logic [31:0]               lsu_data_wdata_i,
  output logic [31:0]               lsu_data_rdata_o,
  output logic                      lsu_data_err_o,
  input  logic                      lsu_resp_valid_i,
  input  logic                      lsu_busy_i,
  // Control signals
  input  logic                      vector_op_i,
  input  logic                      vrf_lsu_req_i,
  input  logic                      is_mem_op_i
);

//////////////////////////////
// First Port Sharing Logic //
//////////////////////////////

typedef enum logic {MOD_B, MOD_A} dmem_op_t;
dmem_op_t prev_op_q, prev_op_d;
logic a_is_master;

// intermediate signals used for port sharing logic
logic data_req_a, data_req_b;
logic data_gnt_a, data_gnt_b;
logic data_rvalid_a, data_rvalid_b;
logic data_we_a, data_we_b;
logic [3:0] data_be_a, data_be_b;
logic [31:0] data_addr_a, data_addr_b;
logic [31:0] data_wdata_a, data_wdata_b;
logic [31:0] data_rdata_a, data_rdata_b;
logic data_err_a, data_err_b;
logic b_resp_valid, b_busy;

// Assign correct intermediate signals for sharing port logic, FSM-LSU if 1 port, FSM1-FSM2 if 2 ports
assign data_req_a = vrf_data_req_i[0];
assign vrf_data_gnt_o[0] = data_gnt_a;
assign vrf_data_rvalid_o[0] = data_rvalid_a;
assign data_we_a = vrf_data_we_i[0];
assign data_be_a = vrf_data_be_i[0];
assign data_addr_a = vrf_data_addr_i[0];
assign data_wdata_a = vrf_data_wdata_i[0];
assign vrf_data_rdata_o[0] = data_rdata_a;
assign vrf_data_err_o[0] = data_err_a;
generate
  if (NumIfs==1) begin
    assign data_req_b = lsu_data_req_i;
    assign lsu_data_gnt_o = data_gnt_b;
    assign lsu_data_rvalid_o = data_rvalid_b;
    assign data_we_b = lsu_data_we_i;
    assign data_be_b = lsu_data_be_i;
    assign data_addr_b = lsu_data_addr_i;
    assign data_wdata_b = lsu_data_wdata_i;
    assign lsu_data_rdata_o = data_rdata_b;
    assign lsu_data_err_o = data_err_b;
    assign b_resp_valid = lsu_resp_valid_i;
    assign b_busy = lsu_busy_i;
  end
  else begin
    assign data_req_b = vrf_data_req_i[1];
    assign vrf_data_gnt_o[1] = data_gnt_b;
    assign vrf_data_rvalid_o[1] = data_rvalid_b;
    assign data_we_b = vrf_data_we_i[1];
    assign data_be_b = vrf_data_be_i[1];
    assign data_addr_b = vrf_data_addr_i[1];
    assign data_wdata_b = vrf_data_wdata_i[1];
    assign vrf_data_rdata_o[1] = data_rdata_b;
    assign vrf_data_err_o[1] = data_err_b;
    assign b_resp_valid = 1'b1;
    assign b_busy = 1'b0;
  end
endgenerate

// Control signal used to manage transitions in FSM
generate
  if (NumIfs==1) begin
    // signal is high when the VRF has control of the data memory, it can happen when the following conditions are met:
    // - it's a vector operation
    // - the VRF didn't request a memory operation
    // - the LSU is not busy with a previously requested memory operation (needed especially for misaligned accesses)
    assign a_is_master = vector_op_i && (!vrf_lsu_req_i && !b_busy);
  end
  else begin
    // with more than one port the first one is shared between two FSMs only if it's a memory operation
    // otherwise each FSM has its own port to work with
    assign a_is_master = vector_op_i && (vrf_data_req_i[0] || !is_mem_op_i);
  end
endgenerate

// INPUTS
// rdata sent to both
assign data_rdata_a = data_rdata_i[0];
assign data_rdata_b = data_rdata_i[0];
// FIRST CYCLE RESPONSES, the grant is given (or not) immediately
assign data_gnt_a = a_is_master && data_gnt_i;
assign data_gnt_b = !a_is_master && data_gnt_i;

// SECOND CYCLE RESPONSES, responses given on the next cycle, FSM needed to keep track of the previous unit
always_ff @(posedge clk_i or negedge rst_ni) begin
  if (!rst_ni) begin
    prev_op_q <= MOD_A;
  end else begin
    if (!vector_op_i) begin
      prev_op_q <= MOD_A;
    end else begin
      prev_op_q <= prev_op_d;
    end
  end
end
always_comb begin
  case (prev_op_q)
    // This state means that the previous master was A, if a keeps being it the FSM doesn't move
    MOD_A: prev_op_d = a_is_master; // correspond to ... = a_is_master ? MOD_A : MOD_B;
    // This state means that the previous master was B.
    // Next state: if not a vector operation the data port keeps beign of the LSU (not optimal for multiple ports since the LSU will not use it)
    MOD_B: prev_op_d = (vector_op_i && b_resp_valid) ? a_is_master : MOD_B;
  endcase
end

// different conditions to ensure that when there is no vector operation the data memory is controlled by the LSU
assign vrf_data_rvalid_o = ((prev_op_q == MOD_A) && vector_op_i) && data_rvalid_i;
assign lsu_data_rvalid_o = ((prev_op_q == MOD_B) || !vector_op_i) && data_rvalid_i;
assign vrf_data_err_o = ((prev_op_q == MOD_A) && vector_op_i) && data_err_i;
assign lsu_data_err_o = ((prev_op_q == MOD_B) || !vector_op_i) && data_err_i;

// OUTPUTS

assign data_req_o = a_is_master ? vrf_data_req_i : lsu_data_req_i;
assign data_we_o = a_is_master ? vrf_data_we_i : lsu_data_we_i;
assign data_be_o = a_is_master ? vrf_data_be_i : lsu_data_be_i;
assign data_addr_o = a_is_master ? vrf_data_addr_i : lsu_data_addr_i;
assign data_wdata_o = a_is_master ? vrf_data_wdata_i : lsu_data_wdata_i;

///////////////////////////
// Ports 2/3 connections //
///////////////////////////

generate
  if (NumIfs==2) begin
    // connect the second interface to: FSM if it's a vector op that is not load/store (each FSM will use a port), LSU if not vector op (scalar LSU use) or if vector load/store
    // OUTPUTS
    assign data_req_o[1] = (vector_op_i && !is_mem_op_i) ? vrf_data_req_i[1] : lsu_data_req_i;
    assign data_we_o[1] = (vector_op_i && !is_mem_op_i) ? vrf_data_we_i[1] : lsu_data_we_i;
    assign data_be_o[1] = (vector_op_i && !is_mem_op_i) ? vrf_data_be_i[1] : lsu_data_be_i;
    assign data_addr_o[1] = (vector_op_i && !is_mem_op_i) ? vrf_data_addr_i[1] : lsu_data_addr_i;
    assign data_wdata_o[1] = (vector_op_i && !is_mem_op_i) ? vrf_data_wdata_i[1] : lsu_data_wdata_i;
    // INPUTS (assigned to both, can be changed later if needed)
    assign vrf_data_gnt_o[1] = data_gnt_i[1];
    assign vrf_data_rvalid_o[1] = data_rvalid_i[1];
    assign vrf_data_rdata_o[1] = data_rdata_i[1];
    assign vrf_data_err_o[1] = data_err_i[1];
    assign lsu_data_gnt_o = data_gnt_i[1];
    assign lsu_data_rvalid_o = data_rvalid_i[1];
    assign lsu_data_rdata_o = data_rdata_i[1];
    assign lsu_data_err_o = data_err_i[1];
  end
  if (NumIfs==3) begin
    // with three ports the third FSM is always connected to the third port
    // OUTPUTS
    assign data_req_o[2] = vrf_data_req_i[2];
    assign data_we_o[2] = vrf_data_we_i[2];
    assign data_be_o[2] = vrf_data_be_i[2];
    assign data_addr_o[2] = vrf_data_addr_i[2];
    assign data_wdata_o[2] = vrf_data_wdata_i[2];
    // INPUTS
    assign vrf_data_gnt_o[2] = data_gnt_i[2];
    assign vrf_data_rvalid_o[2] = data_rvalid_i[2];
    assign vrf_data_rdata_o[2] = data_rdata_i[2];
    assign vrf_data_err_o[2] = data_err_i[2];
  end
endgenerate

endmodule
