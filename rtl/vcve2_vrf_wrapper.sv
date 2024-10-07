module vcve2_vrf_wrapper #(
    parameter int unsigned NumIfs = 1,
    parameter int unsigned VLEN = 128,
    parameter int unsigned PIPE_WIDTH = 32
)(
    // Clock and Reset
    input   logic                       clk_i,
    input   logic                       rst_ni,

    // Data memory ports for top module
    output  logic [NumIfs-1:0]          data_req_o,
    input   logic [NumIfs-1:0]          data_gnt_i,
    input   logic [NumIfs-1:0]          data_rvalid_i,
    input   logic [NumIfs-1:0]          data_err_i,
    input   logic                       data_pmp_err_i,
    output  logic [NumIfs-1:0]          data_we_o,
    output  logic [NumIfs-1:0] [3:0]    data_be_o,
    output  logic [NumIfs-1:0] [31:0]   data_wdata_o,
    input   logic [NumIfs-1:0] [31:0]   data_rdata_i,

    // Read ports
    input   logic                       req_i,
    output  logic [PIPE_WIDTH-1:0]      rdata_a_o, 
    output  logic [PIPE_WIDTH-1:0]      rdata_b_o, 
    output  logic [PIPE_WIDTH-1:0]      rdata_c_o,

    // Write port
    input   logic [PIPE_WIDTH-1:0]      wdata_i,

    // LSU control signals
    output logic                        data_load_addr_o,
    input  logic                        lsu_gnt_i,

    // AGU
    output logic                        agu_load_o,
    output logic                        agu_get_rs1_o,
    output logic                        agu_get_rs2_o,
    output logic                        agu_get_rd_o,
    output logic                        agu_incr_o,

    // ID signals
    input  logic [3:0]                  sel_operation_i,
    input  logic                        memory_op_i,
    input  logic                        unit_stride_i,
    input  logic                        mult_ops_i,
    output logic                        vector_done_o,

    // Slide signals
    input  logic                        slide_op_i,
    input  logic [31:0]                 slide_offset_i,
    input  logic                        is_slide_up_i,

    // LSU signals
    output logic                        lsu_req_o,
    input  logic                        lsu_done_i,

    // CSR signals
    input  vcve2_pkg::vlmul_e           lmul_i,
    input  vcve2_pkg::vsew_e            sew_i,
    input  logic [31:0]                 vl_i
);

    // Internal signals for connecting to instances
    logic [NumIfs-1:0] req;
    logic req_1_d, req_1_q;
    logic [NumIfs-1:0] agu_load, agu_incr;

    logic [NumIfs-1:0] other_done, op_done;

    // Instantiate vcve2_vrf_interface modules
    generate
        genvar i;
        for (i = 0; i < NumIfs; i++) begin : vcve2_instances
            // request signals
            if (i == 0) begin
                assign req[i] = req_i;
            end
            else begin
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    req[i] = 1'b0;
                else
                    req[i] = req[i-1];
                end
            end
            // fsm
            vcve2_vrf_interface #(
                .VLEN(VLEN),
                .PIPE_WIDTH(PIPE_WIDTH)
            ) vcve2_inst (
                .clk_i(clk_i),
                .rst_ni(rst_ni),
                .req_i(req[i]),
                .rdata_a_o(rdata_a_o),
                .rdata_b_o(rdata_b_o),
                .rdata_c_o(rdata_c_o),
                .wdata_i(wdata_i),

                .op_done_o(op_done[i]),
                .other_done_i(other_done[i]),

                .data_req_o(data_req_o[i]),
                .data_gnt_i(data_gnt_i[i]),
                .data_rvalid_i(data_rvalid_i[i]),
                .data_err_i(data_err_i[i]),
                //.data_pmp_err_i(data_pmp_err[i]),
                .data_pmp_err_i(1'b0),
                .data_we_o(data_we_o[i]),
                .data_be_o(data_be_o[i]),
                .data_wdata_o(data_wdata_o[i]),
                .data_rdata_i(data_rdata_i[i]),

                .data_load_addr_o(data_load_addr_o),
                .lsu_gnt_i(lsu_gnt_i),
                .agu_load_o(agu_load[i]),
                .agu_get_rs1_o(agu_get_rs1_o),
                .agu_get_rs2_o(agu_get_rs2_o),
                .agu_get_rd_o(agu_get_rd_o),
                .agu_incr_o(agu_incr[i]),
                .sel_operation_i(sel_operation_i),
                .memory_op_i(memory_op_i),
                .unit_stride_i(unit_stride_i),
                .mult_ops_i(mult_ops_i),
                .vector_done_o(vector_done_o),
                .slide_op_i(slide_op_i),
                .slide_offset_i(slide_offset_i),
                .is_slide_up_i(is_slide_up_i),
                .lsu_req_o(lsu_req_o),
                .lsu_done_i(lsu_done_i),

                .lmul_i(lmul_i),
                .sew_i(sew_i),
                .vl_i(vl_i)
            );
        end

        // signal to synchronize FSMs
        if (NumIfs == 1) begin : gen_done_1
            assign other_done[0] = 1'b1;
        end
        else if (NumIfs == 2) begin : gen_done_2
            assign other_done[0] = op_done[1];
            assign other_done[1] = op_done[0];
        end
        else if (NumIfs == 3) begin : gen_done_3
            assign other_done[0] = op_done[1] & op_done[2];
            assign other_done[1] = op_done[0] & op_done[2];
            assign other_done[2] = op_done[0] & op_done[1];
        end
    endgenerate

    // AGU control signals
    assign agu_load_o = agu_load[0];
    assign agu_incr_o = agu_incr[NumIfs-1];

endmodule
