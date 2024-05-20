module vcve2_fracturable_adder #(
    parameter PIPE_WIDTH = 32
) (
    input  logic [PIPE_WIDTH-1:0] operand_a_i, operand_b_i,
    output logic [PIPE_WIDTH-1:0] result_o,
    input  logic [1:0]            sew_i                 
);

  parameter FRACTURABLE_WIDTH = PIPE_WIDTH + PIPE_WIDTH/8;

  logic [FRACTURABLE_WIDTH-1:0] op_a, op_b, res;
  logic [(PIPE_WIDTH/32)*4-1:0] unused_bits;
  logic split16, split8;

  assign split16 = (sew_i[1]==1'b0) ? 1'b0 : 1'b1;    // if width is 16 we set carry to 0 so that it doesn't propagate
  assign split8 = (sew_i==2'b00) ? 1'b0 : 1'b1;       // if width is 8 we set carry to 0 so that it doesn't propagate

  // inserting the bits to control word size
  generate
    for (genvar i = 0; i < PIPE_WIDTH/32; i++) begin
      assign op_a[i*36 +: 8] = operand_a_i[i*32 +: 8];
      assign op_a[i*36+9 +: 8] = operand_a_i[i*32+8 +: 8];
      assign op_a[i*36+18 +: 8] = operand_a_i[i*32+16 +: 8];
      assign op_a[i*36+27 +: 8] = operand_a_i[i*32+24 +: 8];

      assign op_b[i*36 +: 8] = operand_b_i[i*32 +: 8];
      assign op_b[i*36+9 +: 8] = operand_b_i[i*32+8 +: 8];
      assign op_b[i*36+18 +: 8]= operand_b_i[i*32+16 +: 8];
      assign op_b[i*36+27 +: 8] = operand_b_i[i*32+24 +: 8];

      assign op_a[i*36+35] = 1'b0;  // since it can't be 64 it's always to zero
      assign op_b[i*36+35] = 1'b0;  // since it can't be 64 it's always to zero
      // if width is 16 or 8
      assign op_a[i*36+17] = split16;
      assign op_b[i*36+17] = 1'b0;
      // if width is 8
      assign op_a[i*36+8] = split8;
      assign op_a[i*36+26] = split8;
      assign op_b[i*36+8] = 1'b0;
      assign op_b[i*36+26] = 1'b0;
    end
  endgenerate

  // adder
  assign res = op_a + op_b;

  // extract result
  generate
    for (genvar i = 0; i < PIPE_WIDTH/32; i++) begin
      assign result_o[i*32 +: 8] = res[i*36 +: 8];
      assign result_o[i*32+8 +: 8] = res[i*36+9 +: 8];
      assign result_o[i*32+16 +: 8] = res[i*36+18 +: 8];
      assign result_o[i*32+24 +: 8] = res[i*36+27 +: 8];
      // assign unused bits
      assign unused_bits[i*4] = res[i*36+8];
      assign unused_bits[i*4+1] = res[i*36+17];
      assign unused_bits[i*4+2] = res[i*36+26];
      assign unused_bits[i*4+3] = res[i*36+35];
    end
  endgenerate  

endmodule
