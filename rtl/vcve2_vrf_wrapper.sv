module vcve2_vrf_wrapper #(
    parameter int unsigned NumIfs = 1,
    parameter int unsigned VLEN = 128,
    parameter int unsigned PIPE_WIDTH = 32
)(
    ///////////////////// REGISTER FIlE SIGNALS /////////////////////
    input   logic                       clk_i,
    input   logic                       rst_ni,
    input   logic                       req_i,
    output  logic [PIPE_WIDTH-1:0]      rdata_a_o, 
    output  logic [PIPE_WIDTH-1:0]      rdata_b_o, 
    output  logic [PIPE_WIDTH-1:0]      rdata_c_o,
    input   logic [PIPE_WIDTH-1:0]      wdata_i,

    ///////////////////// DATA MEMORY INTERFACES ////////////////////
    output  logic [NumIfs-1:0]          data_req_o,
    input   logic [NumIfs-1:0]          data_gnt_i,
    input   logic [NumIfs-1:0]          data_rvalid_i,
    input   logic [NumIfs-1:0]          data_err_i,
    input   logic                       data_pmp_err_i,
    output  logic [NumIfs-1:0]          data_we_o,
    output  logic [NumIfs-1:0] [3:0]    data_be_o,
    output  logic [NumIfs-1:0] [31:0]   data_wdata_o,
    input   logic [NumIfs-1:0] [31:0]   data_rdata_i,

    ///////////////////// LSU INTERFACE /////////////////////////////
    output logic                        data_load_addr_o,
    input  logic                        lsu_gnt_i,
    output logic                        lsu_req_o,
    input  logic                        lsu_done_i,

    ///////////////////// AGU INTERFACE /////////////////////////////
    output logic                        agu_load_o,
    output logic [NumIfs-1:0]           agu_get_rs1_o,
    output logic [NumIfs-1:0]           agu_get_rs2_o,
    output logic [NumIfs-1:0]           agu_get_rd_o,
    output logic                        agu_incr_o,

    ///////////////////// CONTROL SIGNALS ///////////////////////////
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

    ///////////////////// CSR ///////////////////////////////////////
    input  vcve2_pkg::vlmul_e           lmul_i,
    input  vcve2_pkg::vsew_e            sew_i,
    input  logic [31:0]                 vl_i
);

    // Wrapper signals
    logic wrapper_state_q, wrapper_state_d;                     // state machine for the wrapper
    // Internal signals for connecting to instances
    logic [NumIfs-1:0] req;
    logic [NumIfs-1:0] fsm_done;
    logic fsm_all_done;
    logic req_1_d, req_1_q;
    logic [NumIfs-1:0] agu_load, agu_incr;
    logic [NumIfs-1:0] other_done, op_done;
    // number of iterations handling signals
    logic init_num_iterations;                                  // control signal, when high it must sample the number of iterations.
    logic [PIPE_WIDTH-1:0] num_bytes_elements;                  // number of bytes to be processed for the current instruction
    logic [PIPE_WIDTH-3:0] num_iterations_q, num_iterations_d;  // counter for the number of iterations
    logic [1:0] offset_q, offset_d;                             // offset for misaligned load/store and slide
    logic [NumIfs-1:0] req_iter, gnt_iter;                      // signals between VRF interfaces and wrapper used to request an iteration

    /////////////////
    // Wrapper FSM //
    /////////////////
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wrapper_state_q <= 1'b0;
        end
        else begin
            wrapper_state_q <= wrapper_state_d;
        end
    end
    always_comb begin
        wrapper_state_d = wrapper_state_q;
        init_num_iterations = 1'b0;
        case (wrapper_state_q)
            1'b0: begin                      // IDLE STATE
                if (req_i) begin
                    wrapper_state_d = 1'b1;
                    init_num_iterations = 1'b1;
                end
            end
            1'b1: begin                      // RUNNING STATE - here in the first cycle req is high, used to initialize things
                if (fsm_all_done) begin
                    vector_done_o = 1'b1;
                    wrapper_state_d = 1'b0;
                end
                wrapper_state_d = 1'b1;
            end
            default: begin
                wrapper_state_d = 1'b0;
            end
        endcase
    end

    //////////////////////////////////
    // Num of Iterations and Offset //
    //////////////////////////////////

    // Num of iterations and offset registers
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            num_iterations_q <= 0;
            offset_q <= 0;
        end
        else begin
            num_iterations_q <= num_iterations_d;
            offset_q <= offset_d;
        end
    end

    // Num of Iterations and offset initialization
    always_comb begin
        num_iterations_d = num_iterations_q;
        offset_d = offset_q;
        num_bytes_elements = '0;
        for (int j=0; j<NumIfs; j++) gnt_iter[j] = 1'b0;
        if (init_num_iterations) begin
            num_bytes_elements = vl_i<<sew_i;
            // In this line a use a subtractor and later I will need a comparator for num_iterations, would it be possible to reuse this?
            // num_iterations_d = slide_op_i ? num_bytes_elements[31:2] - slide_offset_i[31:2] : num_bytes_elements[31:2];
            num_iterations_d = num_bytes_elements[31:2];
            offset_d = num_bytes_elements[1:0];
        end else begin
            for (int j=0; j<NumIfs; j++) begin
                if (req_iter[j] && (num_iterations_q>0)) begin
                    num_iterations_d = num_iterations_q-1;
                    gnt_iter[j] = 1'b1;
                end
            end
        end
    end


    // Instantiate vcve2_vrf_interface modules
    generate
        genvar i;

        // Generation of request signals for single instances of FSM, they are all the delayed version of the previous one
        // Also the first one is delayed to leave one cycle to the wrapper for num_iterations and offset calculation
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                req[0] <= 1'b0;
            end else begin
                req[0] <= req_i;
            end
        end
        for (i = 1; i < NumIfs; i++) begin : req_regs
            always_ff @(posedge clk_i or negedge rst_ni) begin
                if (!rst_ni)
                    req[i] <= 1'b0;
                else begin
                    req[i] <= req[i-1];
                end
            end
        end

        // FSMs
        for (i = 0; i < NumIfs; i++) begin : vcve2_instances
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

                // multiple ports support
                .op_done_o(op_done[i]),
                .other_done_i(other_done[i]),
                .req_iter_o(req_iter[i]),
                .gnt_iter_i(gnt_iter[i]),

                // data memory interface
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
                .lsu_req_o(lsu_req_o),
                .lsu_done_i(lsu_done_i),
                .agu_load_o(agu_load[i]),
                .agu_get_rs1_o(agu_get_rs1_o[i]),
                .agu_get_rs2_o(agu_get_rs2_o[i]),
                .agu_get_rd_o(agu_get_rd_o[i]),
                .agu_incr_o(agu_incr[i]),
                .sel_operation_i(sel_operation_i),
                .memory_op_i(memory_op_i),
                .unit_stride_i(unit_stride_i),
                .mult_ops_i(mult_ops_i),
                .vector_done_o(fsm_done[i]),
                .slide_op_i(slide_op_i),
                .slide_offset_i(slide_offset_i),
                .is_slide_up_i(is_slide_up_i),

                .lmul_i(lmul_i),
                .sew_i(sew_i),
                .vl_i(vl_i)
            );
        end

        // signal to synchronize FSMs
        if (NumIfs == 1) begin : gen_done_1
            assign other_done[0] = 1'b1;
            assign fsm_all_done = fsm_done[0];
        end
        else if (NumIfs == 2) begin : gen_done_2
            assign other_done[0] = op_done[1];
            assign other_done[1] = op_done[0];
            assign fsm_all_done = fsm_done[0] & fsm_done[1];
        end
        else if (NumIfs == 3) begin : gen_done_3
            assign other_done[0] = op_done[1] & op_done[2];
            assign other_done[1] = op_done[0] & op_done[2];
            assign other_done[2] = op_done[0] & op_done[1];
            assign fsm_all_done = fsm_done[0] & fsm_done[1] & fsm_done[2];
        end
    endgenerate

    // AGU control signals
    assign agu_load_o = agu_load[0];
    assign agu_incr_o = agu_incr[NumIfs-1];

endmodule
