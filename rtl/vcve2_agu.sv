module vcve2_agu #(
    parameter int unsigned NumIfs = 1,
    parameter AddrWidth = 32
) (
    input logic clk_i,
    input logic rst_ni,

    // input logic [....] vrf_base_addr_i, // base address of the VRF
    // addresses of registers
    input logic [4:0] rs1_i,
    input logic [4:0] rs2_i,
    input logic [4:0] rd_i,

    // control signals from VRF
    input logic load_i,           // parallel load_i for the counters
    input logic get_rs1_i,        // generate rs1
    input logic get_rs2_i,        // generate rs2
    input logic get_rd_i,         // generate rd
    input logic incr_i,

    // slide support signals
    input logic is_slide_i,       // the current instruction is a slide
    input logic is_slide_up_i,    // 1 - slide up, 0 - slide down

    // to/from pipeline
    input  logic [AddrWidth-1:0] addr_i,   // address with OFFSET
    output logic [AddrWidth-1:0] addr_o    // requested address
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
        if (is_slide_i && !is_slide_up_i && load_i) addr_rs2_d = addr_i[31:2];      // in slide down the address is vs2 since we start reading it from OFFSET
        else if (is_slide_i && is_slide_up_i && load_i) addr_rd_d = addr_i[31:2];   // in slide up the address is vd since we start writing it from OFFSET
    end

    ////////////
    // OUTPUT //
    ////////////

    // Multiplexer for the output address
    always_comb begin
        // if the instruction is a slide we need to load the address incremented by offset, to do so the adder is exploted
        if (load_i && is_slide_i) begin
            addr_o = {!is_slide_up_i ? VREG_START_ADDR[rs2_i][31:2] : VREG_START_ADDR[rd_i][31:2], 2'b00};
        end else begin
            addr_o = get_rs1_i ? {addr_rs1_q, 2'b00} :
                     get_rs2_i ? {addr_rs2_q, 2'b00} :
                     get_rd_i  ? {addr_rd_q, 2'b00}  : '0;
        end
    end

    
endmodule
