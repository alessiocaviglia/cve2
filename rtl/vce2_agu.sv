module vce2_agu #(
    parameter AddrWidth = 32
) (
    input logic clk_i,
    input logic rst_ni,

    // from/to PIPELINE
    input logic [AddrWidth-3:0] addr_i,
    output logic raddr_a_sel_o,                 // select signal for address of first port of RF, used to read rd
    output logic agu_addr_sel_o,                // select signal for multiplexer on agu's input, selects between rdata a and b

    // from/to VRF
    input logic load,           // parallel load for the counters
    input logic get_rs1,        // generate rs1
    input logic get_rs2,        // generate rs2
    input logic get_rd_noincr,  // generate rd without increment after
    input logic get_rd,         // generate rd
    output logic ready_o,       // load of addresses complete

    // to MEMORY interface
    output logic [AddrWidth-1:0] addr_o
);

    // counter signals
    logic incr_rs1, incr_rs2, incr_rd, ld_rs1, ld_rs2, ld_rd;
    logic [AddrWidth-3:0] addr_rs1_q, addr_rs2_q, addr_rd_q, addr_rs1_d, addr_rs2_d, addr_rd_d;
    // FSM signals
    logic [1:0] state, next_state;

    /////////
    // FSM //
    /////////

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state <= 2'b00;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        ld_rs1 = 1'b0;
        ld_rs2 = 1'b0;
        ld_rd = 1'b0;
        raddr_a_sel_o = 1'b0;
        agu_addr_sel_o = 1'b0;
        ready_o = 1'b0;
        case (state)
            2'b00: begin
                if (load==1'b1) begin
                    next_state = 2'b01;
                    ld_rs1 = 1'b1;
                end else begin
                    next_state = 2'b00;
                end
            end
            2'b01: begin
                next_state = 2'b10;
                raddr_a_sel_o = 1'b1;   // select rd as first RF address
                ld_rd = 1'b1;
            end
            2'b10: begin
                next_state = 2'b11;
                agu_addr_sel_o = 1'b1;  // select the second RF port
                ld_rs2 = 1'b1;
            end
            2'b11: begin
                next_state = 2'b00;
                ready_o = 1;
            end
            default: next_state = 2'b00;
        endcase
    end

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
        addr_rs1_d = ld_rs1 ? addr_i : incr_rs1 ? addr_rs1_q + 1 : addr_rs1_q;
        addr_rs2_d = ld_rs2 ? addr_i : incr_rs2 ? addr_rs2_q + 1 : addr_rs2_q;
        addr_rd_d = ld_rd ? addr_i : incr_rd ? addr_rd_q + 1 : addr_rd_q;
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

    ////////////
    // OUTPUT //
    ////////////

    // Multiplexer for the output address
    always_comb begin
        addr_o = get_rs1 ? {addr_rs1_q, 2'b00} :
                 get_rs2 ? {addr_rs2_q, 2'b00} :
                 get_rd || get_rd_noincr ? {addr_rd_q, 2'b00} : '0;
    end

    
endmodule
