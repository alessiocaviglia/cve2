module vce2_agu #(
    parameter AddrWidth = 32
) (
    input logic clk_i,
    input logic rst_ni,

    // from/to PIPELINE
    input logic [4:0] rs1_i,      // addresses of the registers
    input logic [4:0] rs2_i,
    input logic [4:0] rd_i,

    // from/to VRF
    input logic load_i,           // parallel load_i for the counters
    input logic get_rs1_i,        // generate rs1
    input logic get_rs2_i,        // generate rs2
    input logic get_rd_i,         // generate rd
    input logic incr_i,

    // to MEMORY interface
    output logic [AddrWidth-1:0] addr_o
);

    import vcve2_pkg::*;

    // counter signals
    logic [AddrWidth-3:0] addr_rs1_q, addr_rs2_q, addr_rd_q, addr_rs1_d, addr_rs2_d, addr_rd_d;

    //////////////
    // COUNTERS //
    //////////////

    // Sequential logic for the counters
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            addr_rs1_q <= '0;
            addr_rs2_q <= '0;
            addr_rd_q <= '0;
        end else begin
            addr_rs1_q <= addr_rs1_d;
            addr_rs2_q <= addr_rs2_d;
            addr_rd_q <= addr_rd_d;
        end
    end

    // Combinational logic for the counters
    always_comb begin
        addr_rs1_d = load_i ? VREG_START_ADDR[rs1_i][31:2] : (get_rs1_i && incr_i) ? addr_rs1_q + 1 : addr_rs1_q;
        addr_rs2_d = load_i ? VREG_START_ADDR[rs2_i][31:2] : (get_rs2_i && incr_i) ? addr_rs2_q + 1 : addr_rs2_q;
        addr_rd_d = load_i ? VREG_START_ADDR[rd_i][31:2] : (get_rd_i && incr_i) ? addr_rd_q + 1 : addr_rd_q;
    end

    ////////////
    // OUTPUT //
    ////////////

    // Multiplexer for the output address
    always_comb begin
        addr_o = get_rs1_i ? {addr_rs1_q, 2'b00} :
                 get_rs2_i ? {addr_rs2_q, 2'b00} :
                 get_rd_i ? {addr_rd_q, 2'b00} : '0;
    end

    
endmodule
