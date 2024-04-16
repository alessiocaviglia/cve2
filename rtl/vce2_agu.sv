module vce2_agu #(
    parameter AddrWidth = 32
) (
    input logic clk_i,
    input logic rst_ni,

    // from PIPELINE
    input logic [AddrWidth-3:0] addr_rs1_i,
    input logic [AddrWidth-3:0] addr_rs2_i,
    input logic [AddrWidth-3:0] addr_rd_i,

    // from VRF
    input logic load,           // parallel load for the counters
    input logic get_rs1,        // generate rs1
    input logic get_rs2,        // generate rs2
    input logic get_rd_noincr,  // generate rd without increment after
    input logic get_rd,         // generate rd

    // to MEMORY interface
    output logic [AddrWidth-1:0] addr_o
);

    logic incr_rs1, incr_rs2, incr_rd;
    logic [AddrWidth-3:0] addr_rs1_s, addr_rs2_s, addr_rd_s;

    // Four 30 bit counters for the addresses
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            addr_rs1_s <= 0;
            addr_rs2_s <= 0;
            addr_rd_s <= 0;
        end else begin
            if (load) begin
                addr_rs1_s <= addr_rs1_i;
                addr_rs2_s <= addr_rs2_i;
                addr_rd_s <= addr_rd_i;
            end else begin
                addr_rs1_s <= incr_rs1 ? addr_rs1_s + 1 : addr_rs1_s;
                addr_rs2_s <= incr_rs2 ? addr_rs2_s + 1 : addr_rs2_s;
                addr_rd_s <= incr_rd ? addr_rd_s + 1 : addr_rd_s;
            end
        end
    end

    // Delayed increment for the read/write signals
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            incr_rs1 <= 0;
            incr_rs2 <= 0;
            incr_rd <= 0;
        end else begin
            incr_rs1 <= get_rs1;
            incr_rs2 <= get_rs2;
            incr_rd <= get_rd;
        end
    end

    // Multiplexer for the output address
    always_comb begin
        addr_o = get_rs1 ? {addr_rs1_s, 2'b00} :
                 get_rs2 ? {addr_rs2_s, 2'b00} :
                 get_rd || get_rd_noincr ? {addr_rd_s, 2'b00} : '0;
    end

    
endmodule
