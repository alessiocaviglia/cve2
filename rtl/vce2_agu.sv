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
    input logic load_i,           // parallel load_i for the counters
    input logic get_rs1_i,        // generate rs1
    input logic get_rs2_i,        // generate rs2
    input logic get_rd_i,         // generate rd
    input logic incr_i,
    output logic ready_o,       // load_i of addresses complete

    // to MEMORY interface
    output logic [AddrWidth-1:0] addr_o
);

    // counter signals
    logic ld_rs1, ld_rs2, ld_rd;
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
                if (load_i==1'b1) begin
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
                next_state = 2'b00;
                agu_addr_sel_o = 1'b1;  // select the second RF port
                ld_rs2 = 1'b1;
                ready_o = 1'b1;
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
        addr_rs1_d = ld_rs1 ? addr_i : (get_rs1_i && incr_i) ? addr_rs1_q + 1 : addr_rs1_q;
        addr_rs2_d = ld_rs2 ? addr_i : (get_rs2_i && incr_i) ? addr_rs2_q + 1 : addr_rs2_q;
        addr_rd_d = ld_rd ? addr_i : (get_rd_i && incr_i) ? addr_rd_q + 1 : addr_rd_q;
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
