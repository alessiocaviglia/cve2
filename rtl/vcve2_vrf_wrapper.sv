module vcve2_vrf_wrapper #(
    parameter int unsigned NUM_INSTANCES = 3,
    parameter int unsigned VLEN = 128,
    parameter int unsigned PIPE_WIDTH = 32
)(
    // Clock and Reset
    input   logic                       clk_i,
    input   logic                       rst_ni,

    // Data memory ports for top module
    output  logic                       data_req_o,
    input   logic                       data_gnt_i,
    input   logic                       data_rvalid_i,
    input   logic                       data_err_i,
    input   logic                       data_pmp_err_i,
    output  logic                       data_we_o,
    output  logic [3:0]                 data_be_o,
    output  logic [31:0]                data_wdata_o,
    input   logic [31:0]                data_rdata_i,

    output  logic                       data_req_1_o,
    input   logic                       data_gnt_1_i,
    input   logic                       data_rvalid_1_i,
    input   logic                       data_err_1_i,
    //input   logic                       data_pmp_err_1_i,
    output  logic                       data_we_1_o,
    output  logic [3:0]                 data_be_1_o,
    output  logic [31:0]                data_wdata_1_o,
    input   logic [31:0]                data_rdata_1_i,

    /*output  logic                       data_req_2_o,
    input   logic                       data_gnt_2_i,
    input   logic                       data_rvalid_2_i,
    input   logic                       data_err_2_i,
    //input   logic                       data_pmp_err_2_i,
    output  logic                       data_we_2_o,
    output  logic [3:0]                 data_be_2_o,
    output  logic [31:0]                data_wdata_2_o,
    input   logic [31:0]                data_rdata_2_i,*/

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
    input  logic                        interleaved_i,
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

    logic sel;

    // Internal signals for connecting to instances
    logic [NUM_INSTANCES-1:0] data_req;
    logic [NUM_INSTANCES-1:0] data_gnt;
    logic [NUM_INSTANCES-1:0] data_rvalid;
    logic [NUM_INSTANCES-1:0] data_err;
    logic [NUM_INSTANCES-1:0] data_pmp_err;
    logic [NUM_INSTANCES-1:0] data_we;
    logic [3:0]               data_be  [NUM_INSTANCES-1:0];
    logic [31:0]              data_wdata [NUM_INSTANCES-1:0];
    logic [31:0]              data_rdata [NUM_INSTANCES-1:0];
    logic [NUM_INSTANCES-1:0] req;
    logic req_1_d, req_1_q;

    assign req_1_d = req_i;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            req_1_q <= 1'b0;
        end else begin
            req_1_q <= req_1_d;
        end
    end
    assign req[0] = req_i;
    assign req[1] = req_1_q;

    // Instantiate vcve2_vrf_interface modules
    generate
        genvar i;
        for (i = 0; i < NUM_INSTANCES; i++) begin : vcve2_instances
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

                .data_req_o(data_req[i]),
                .data_gnt_i(data_gnt[i]),
                .data_rvalid_i(data_rvalid[i]),
                .data_err_i(data_err[i]),
                //.data_pmp_err_i(data_pmp_err[i]),
                .data_pmp_err_i(1'b0),
                .data_we_o(data_we[i]),
                .data_be_o(data_be[i]),
                .data_wdata_o(data_wdata[i]),
                .data_rdata_i(data_rdata[i]),

                .data_load_addr_o(data_load_addr_o),
                .lsu_gnt_i(lsu_gnt_i),
                .agu_load_o(agu_load_o),
                .agu_get_rs1_o(agu_get_rs1_o),
                .agu_get_rs2_o(agu_get_rs2_o),
                .agu_get_rd_o(agu_get_rd_o),
                .agu_incr_o(agu_incr_o),
                .sel_operation_i(sel_operation_i),
                .memory_op_i(memory_op_i),
                .unit_stride_i(unit_stride_i),
                .interleaved_i(interleaved_i),
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
    endgenerate

    assign sel=1'b1;

    // Connect the top-level data memory ports
    assign data_req_o = data_req[0];
    assign data_gnt[0] = data_gnt_i;
    assign data_rvalid[0] = data_rvalid_i;
    assign data_err[0] = data_err_i;
    //assign data_pmp_err[0] = data_pmp_err_i;
    assign data_we_o = data_we[0];
    assign data_be_o = data_be[0];
    assign data_wdata_o = data_wdata[0];
    assign data_rdata[0] = data_rdata_i;

    assign data_req_1_o = sel ? data_req[1] : data_req[0];
    assign data_gnt[1] = data_gnt_1_i;
    assign data_rvalid[1] = data_rvalid_1_i;
    assign data_err[1] = data_err_1_i;
    //assign data_pmp_err[1] = data_pmp_err_1_i;
    assign data_we_1_o = sel ? data_we[1] : data_we[0];
    assign data_be_1_o = sel ? data_be[1] : data_be[0];
    assign data_wdata_1_o = sel ? data_wdata[1] : data_wdata[0];
    assign data_rdata[1] = data_rdata_1_i;
/*
    if (NUM_INSTANCES > 2) begin
        assign data_req_2_o = data_req[2];
        assign data_gnt[2] = data_gnt_2_i;
        assign data_rvalid[2] = data_rvalid_2_i;
        assign data_err[2] = data_err_2_i;
        //assign data_pmp_err[2] = data_pmp_err_2_i;
        assign data_we_2_o = data_we[2];
        assign data_be_2_o = data_be[2];
        assign data_wdata_2_o = data_wdata[2];
        assign data_rdata[2] = data_rdata_2_i;
    end else begin
        assign data_req_2_o = 1'b0;
        assign data_we_2_o = 1'b0;
        assign data_be_2_o = 4'b0;
        assign data_wdata_2_o = 32'b0;
    end*/

endmodule
