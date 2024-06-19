module vcve2_fracturable_adder #(
    parameter PIPE_WIDTH = 32
) (
    input  logic [PIPE_WIDTH:0] operand_a_i, operand_b_i,
    output logic [PIPE_WIDTH+1:0] result_o,
    input  logic [1:0]            sew_i,
    input  logic                  is_sub_i                 
);

  logic c0, c1, c2, c3;
  logic split8_n, split16_n;

  // Control bits: 0 - stop carry, 1 - propgate carry
  assign split8_n = (sew_i==2'b00) ? 0 : 1;
  assign split16_n = (sew_i[1]==1'b0) ? 0 : 1;

  // First bit of the adder, required by the scalar core
  // The subtraction carry in bit is already embedded in the LSB of operand_b_i
  assign result_o[0] = operand_a_i[0] ^ operand_b_i[0];
  assign c0 = operand_a_i[0] & operand_b_i[0];

  // 4 8-bit adder with control on carry propagate
  assign {c1, result_o[8:1]} = operand_a_i[8:1] + operand_b_i[8:1] + {7'b0, c0};
  assign {c2, result_o[16:9]} = operand_a_i[16:9] + operand_b_i[16:9] + {7'b0, (c1 & split8_n) | (!split8_n & is_sub_i)};
  assign {c3, result_o[24:17]} = operand_a_i[24:17] + operand_b_i[24:17] + {7'b0, (c2 & split16_n) | (!split16_n & is_sub_i)};
  assign result_o[33:25] = operand_a_i[32:25] + operand_b_i[32:25] + {7'b0, (c3 & split8_n) | (!split8_n & is_sub_i)};

endmodule

