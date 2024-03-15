/*  Rigth now this module is useless since it's just use to connect the core
to the RAM primitives but I will keep it since I think the content will most definetely need to change */

module vregfile #(
    parameter int unsigned                 DataWidth   = 128,
    parameter int unsigned                 AddrWidth   = 5
) (
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,
    // Read and write port
    input  logic                 req_i,
    input  logic                 we_i,
    input  logic [AddrWidth-1:0] addr_i,
    input  logic [DataWidth-1:0] wdata_i,
    output logic [DataWidth-1:0] rdata_o
);

    // Instantiate prim_generic_ram_1p
    prim_generic_ram_1p #(
        .Width(DataWidth),
        .Depth(2**AddrWidth),
        .DataBitsPerMask(1), // Assuming 1 bit per mask
        .MemInitFile("") // Assuming no initialization file
    ) ram_inst (
        .clk_i(clk_i),
        .req_i(req_i),
        .write_i(we_i),
        .addr_i(addr_i),
        .wdata_i(wdata_i),
        .wmask_i({DataWidth{1'b1}}), // Assuming write mask is always enabled
        .rdata_o(rdata_o),
        .cfg_i('0) // Assuming default configuration
    );

endmodule