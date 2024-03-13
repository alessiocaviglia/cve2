module vregfile #(
    parameter int unsigned                 DataWidth   = 128,
    parameter int unsigned                 AddrWidth   = 5
) (
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    // Read and write port
    input  logic                 we_i,
    input  logic [AddrWidth-1:0] addr_i,
    input  logic [DataWidth-1:0] wdata_i,
    output logic [DataWidth-1:0] rdata_o

);

  localparam int unsigned NUM_WORDS = 2 ** AddrWidth;

  logic [NUM_WORDS-1:0][DataWidth-1:0] mem;

  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (!rst_ni) begin
      mem <= '0;
    end else if (we_i) begin
      mem[addr_i] <= wdata_i;
    end
  end

  assign rdata_o = mem[addr_i];

endmodule
