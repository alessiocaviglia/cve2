// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Example clock gating module for yosys synthesis

module vcve2_clock_gate (
  input  clk_i,
  input  en_i,
  input  scan_cg_en_i,
  output clk_o
);

  reg en_latch;

  always @* begin
    if (!clk_i) begin
      en_latch = en_i | test_en_i;
    end
  end
  assign clk_o = en_latch & clk_i;

endmodule
