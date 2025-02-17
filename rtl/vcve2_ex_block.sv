// Copyright lowRISC contributors.
// Copyright 2018 ETH Zurich and University of Bologna, see also CREDITS.md.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Execution stage
 *
 * Execution block: Hosts ALU and MUL/DIV unit
 */
module vcve2_ex_block #(
  parameter vcve2_pkg::rv32m_e RV32M           = vcve2_pkg::RV32MFast,
  parameter vcve2_pkg::rv32b_e RV32B           = vcve2_pkg::RV32BNone
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // ALU
  input  vcve2_pkg::alu_op_e     alu_operator_i,
  input  logic [31:0]           alu_operand_a_i,
  input  logic [31:0]           alu_operand_b_i,
  input  logic [31:0]           alu_operand_c_i,            // Vector extension        
  input  logic                  alu_instr_first_cycle_i,

  // Multiplier/Divider
  input  vcve2_pkg::md_op_e      multdiv_operator_i,
  input  logic                  mult_en_i,             // dynamic enable signal, for FSM control
  input  logic                  div_en_i,              // dynamic enable signal, for FSM control
  input  logic                  mult_sel_i,            // static decoder output, for data muxes
  input  logic                  div_sel_i,             // static decoder output, for data muxes
  input  logic  [1:0]           multdiv_signed_mode_i,
  input  logic [31:0]           multdiv_operand_a_i,
  input  logic [31:0]           multdiv_operand_b_i,

  // intermediate val reg
  output logic [1:0]            imd_val_we_o,
  output logic [33:0]           imd_val_d_o[2],
  input  logic [33:0]           imd_val_q_i[2],

  // Outputs
  output logic [31:0]           alu_adder_result_ex_o, // to LSU
  output logic [31:0]           result_ex_o,
  output logic [31:0]           branch_target_o,       // to IF
  output logic                  branch_decision_o,     // to ID

  output logic                  ex_valid_o,            // EX has valid output

  // Vector extension
  input  logic                  vec_instr_i,
  input  logic                  mem_op_i,
  input  logic [2:0]            vsew_i
);

  import vcve2_pkg::*;

  logic [31:0] alu_result, multdiv_result;

  logic [32:0] multdiv_alu_operand_b, multdiv_alu_operand_a;
  logic [33:0] alu_adder_result_ext;
  logic        alu_cmp_result, alu_is_equal_result;
  logic        multdiv_valid;
  logic        multdiv_sel;
  logic [31:0] alu_imd_val_q[2];
  logic [31:0] alu_imd_val_d[2];
  logic [ 1:0] alu_imd_val_we;
  logic [33:0] multdiv_imd_val_d[2];
  logic [ 1:0] multdiv_imd_val_we;
  // Additions for vector extensions
  logic [31:0] alu_operand_a, alu_operand_b;
  logic [31:0] multdiv_operand_b;

  /*
    The multdiv_i output is never selected if RV32M=RV32MNone
    At synthesis time, all the combinational and sequential logic
    from the multdiv_i module are eliminated
  */
  if (RV32M != RV32MNone) begin : gen_multdiv_m
    assign multdiv_sel = mult_sel_i | div_sel_i;
  end else begin : gen_multdiv_no_m
    assign multdiv_sel = 1'b0;
  end

  // Intermediate Value Register Mux
  assign imd_val_d_o[0] = multdiv_sel ? multdiv_imd_val_d[0] : {2'b0, alu_imd_val_d[0]};
  assign imd_val_d_o[1] = multdiv_sel ? multdiv_imd_val_d[1] : {2'b0, alu_imd_val_d[1]};
  assign imd_val_we_o   = multdiv_sel ? multdiv_imd_val_we : alu_imd_val_we;

  assign alu_imd_val_q = '{imd_val_q_i[0][31:0], imd_val_q_i[1][31:0]};

  assign result_ex_o  = multdiv_sel ? multdiv_result : (alu_operator_i == ALU_SLIDE) ? alu_operand_b_i : alu_result;

  // branch handling
  assign branch_decision_o  = alu_cmp_result;

  // Unused bt_operand signals cause lint errors, this avoids them
  //logic [31:0] unused_bt_a_operand, unused_bt_b_operand;

  assign branch_target_o = alu_adder_result_ex_o;

  ///////////////////////
  // Operand selection //
  ///////////////////////
  
  // multdiv_result is on operand b so that I can reuse the already present negation in the ALU
  always_comb begin
    alu_operand_a = alu_operand_a_i;
    alu_operand_b = alu_operand_b_i;
    multdiv_operand_b = multdiv_operand_b_i;

    case (alu_operator_i)
      ALU_MOVE: begin
        alu_operand_b = '0;
      end
      ALU_MAC: begin
        alu_operand_a = alu_operand_c_i;
        alu_operand_b = multdiv_result;
      end
      ALU_NMSAC: begin
        alu_operand_a = alu_operand_c_i;
        alu_operand_b = multdiv_result;
      end
      ALU_MADD: begin
        alu_operand_a = alu_operand_c_i;
        alu_operand_b = multdiv_result;
        multdiv_operand_b = alu_operand_c_i;
      end
      ALU_NMSUB: begin
        alu_operand_a = alu_operand_c_i;
        alu_operand_b = multdiv_result;
        multdiv_operand_b = alu_operand_c_i;
      end
      default: ;
    endcase

  end

  /////////
  // ALU //
  /////////

  vcve2_alu #(
    .RV32B(RV32B)
  ) alu_i (
    .operator_i         (alu_operator_i),
    .operand_a_i        (alu_operand_a),
    .operand_b_i        (alu_operand_b),
    .instr_first_cycle_i(alu_instr_first_cycle_i),
    .imd_val_q_i        (alu_imd_val_q),
    .imd_val_we_o       (alu_imd_val_we),
    .imd_val_d_o        (alu_imd_val_d),
    .multdiv_operand_a_i(multdiv_alu_operand_a),
    .multdiv_operand_b_i(multdiv_alu_operand_b),
    .multdiv_sel_i      (multdiv_sel),
    .adder_result_o     (alu_adder_result_ex_o),
    .adder_result_ext_o (alu_adder_result_ext),
    .result_o           (alu_result),
    .comparison_result_o(alu_cmp_result),
    .is_equal_result_o  (alu_is_equal_result),
    .vec_instr_i        (vec_instr_i),            // Vector extension
    .mem_op_i           (mem_op_i),               // Vector extension
    .vsew_i             (vsew_i)                  // Vector extension
  );

  ////////////////
  // Multiplier //
  ////////////////

  if (RV32M == RV32MSlow) begin : gen_multdiv_slow
    vcve2_multdiv_slow multdiv_i (
      .clk_i             (clk_i),
      .rst_ni            (rst_ni),
      .mult_en_i         (mult_en_i),
      .div_en_i          (div_en_i),
      .mult_sel_i        (mult_sel_i),
      .div_sel_i         (div_sel_i),
      .operator_i        (multdiv_operator_i),
      .signed_mode_i     (multdiv_signed_mode_i),
      .op_a_i            (multdiv_operand_a_i),
      .op_b_i            (multdiv_operand_b_i),
      .alu_adder_ext_i   (alu_adder_result_ext),
      .alu_adder_i       (alu_adder_result_ex_o),
      .equal_to_zero_i   (alu_is_equal_result),
      .valid_o           (multdiv_valid),
      .alu_operand_a_o   (multdiv_alu_operand_a),
      .alu_operand_b_o   (multdiv_alu_operand_b),
      .imd_val_q_i       (imd_val_q_i),
      .imd_val_d_o       (multdiv_imd_val_d),
      .imd_val_we_o      (multdiv_imd_val_we),
      .multdiv_ready_id_i(1'b1),
      .multdiv_result_o  (multdiv_result)
    );
  end else if (RV32M == RV32MFast || RV32M == RV32MSingleCycle) begin : gen_multdiv_fast
    vcve2_multdiv_fast #(
      .RV32M(RV32M)
    ) multdiv_i (
      .clk_i             (clk_i),
      .rst_ni            (rst_ni),
      .mult_en_i         (mult_en_i),
      .div_en_i          (div_en_i),
      .mult_sel_i        (mult_sel_i),
      .div_sel_i         (div_sel_i),
      .operator_i        (multdiv_operator_i),
      .signed_mode_i     (multdiv_signed_mode_i),
      .op_a_i            (multdiv_operand_a_i),
      .op_b_i            (multdiv_operand_b),
      .alu_operand_a_o   (multdiv_alu_operand_a),
      .alu_operand_b_o   (multdiv_alu_operand_b),
      .alu_adder_ext_i   (alu_adder_result_ext),
      .alu_adder_i       (alu_adder_result_ex_o),
      .equal_to_zero_i   (alu_is_equal_result),
      .imd_val_q_i       (imd_val_q_i),
      .imd_val_d_o       (multdiv_imd_val_d),
      .imd_val_we_o      (multdiv_imd_val_we),
      .valid_o           (multdiv_valid),
      .multdiv_result_o  (multdiv_result),
      .vec_instr_i       (vec_instr_i),
      .vsew_i            (vsew_i)
    );
  end

  // Multiplier/divider may require multiple cycles. The ALU output is valid in the same cycle
  // unless the intermediate result register is being written (which indicates this isn't the
  // final cycle of ALU operation).
  assign ex_valid_o = multdiv_sel ? multdiv_valid : ~(|alu_imd_val_we);

endmodule
