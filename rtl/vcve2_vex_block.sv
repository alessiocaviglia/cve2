/**
* Execution stage for Vector instructions
*
* Contains the vector ALU and MUL/DIV unit
*/

module vcve2_vex_block #(
    parameter int unsigned ELEN = 32,
    parameter int unsigned XLEN = 32
) (
    input  logic                      clk_i,
    input  logic                      rst_ni,
    // Input operands
    input  logic [ELEN-1:0]           valu_operand_a,
    input  logic [ELEN-1:0]           valu_operand_b,
    input  logic [ELEN-1:0]           valu_operand_c,
    input  vcve2_pkg::valu_op_e       valu_operator,
    // Output wb value
    output logic [ELEN-1:0]           vec_result_ex_o
);

  import vcve2_pkg::*;

    // case to select the correct operation
    always_comb begin 
        unique case (valu_operator)
            VALU_MOVE: begin
                vec_result_ex_o = valu_operand_a;
            end
            VALU_ADD: begin
                vec_result_ex_o = valu_operand_a + valu_operand_b;
            end
            default: begin
                vec_result_ex_o = 0;
            end
        endcase
    end

endmodule
