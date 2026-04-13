//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================


module mm_wrdbuf
import mm_pkg::*;
#(
    parameter NID_W                 = 11,
    parameteR ADDR_WIDTH            = 60,
    parameter WRDATBUF_DEPTH        = 4

) (
    input   bit                                                             clk,
    input   bit                                                             rstn,
    // wdata from DUT
    input   logic [MST_DATCHN_NUMS-1:0]                                     valid_NCBWrData,
    input   wdata_info_t [MST_DATCHN_NUMS-1:0]                              wdata_info,

    input   logic                                                           wrdbuf_valid,
    input   wrreq_t                                                         wrdbuf_req,

    // To glb sram
    output  req_upld_t                                                      glbsram_wrreq,
    output  logic                                                           glbsram_wrvalid,
    // ras
    output  logic                                                           err

);

    localparam WRBUF_PTR_W          = $clog2(WRDATBUF_DEPTH);
    localparam DATCHN_W             = $clog2(MST_DATCHN_NUMS);

    wdata_info_t                    wr_datbuf[WRDATBUF_DEPTH];
    logic [WRDATBUF_DEPTH-1:0]      wr_datbuf_valid;
    logic [DATCHN_W-1:0]            wrchn_idx;

    logic [WRBUF_PTR_W-1:0]         datbuf_alloc_ptr;
    logic [WRBUF_PTR_W-1:0]         datbuf_dealloc_ptr;
    logic [WRBUF_PTR_W-1:0]         datbuf_issue_ptr;
    logic [WRBUF_PTR_W-1:0]         datbuf_match_ptr;
    logic                           match_flag;
    logic [WRBUF_PTR_W-1:0]         datbuf_empty_idx;
    logic [WRDATBUF_DEPTH-1:0]      first_alloc;
    logic [WRDATBUF_DEPTH-1:0]      datid_unk;

    bit                             err_datbuf_ovf;
    bit                             err_dataline_ovf;
    bit                             err_dataid_unk;

    assign err                  = err_datbuf_ovf | err_dataline_ovf | err_dataid_unk;
    // In case datbuf is full
    assign err_datbuf_ovf       = &wr_datbuf_valid && (match_flag == 0) && valid_NCBWrData; 
    // In case dataline is narrow than full trans' data width
    assign err_dataline_ovf     = wdat_datacnt > 4;
    assign err_dataid_unk       = |datid_unk;



    // CAM wr req and relative wr data 
    always_comb begin
        datbuf_match_ptr = 0;
        wrchn_idx = 0;
        match_flag = 0;
        if (|valid_NCBWrData) begin
            for (int i = 0; i < WRDATBUF_DEPTH; i++) begin: u_match_entry
                for (int j = 0; j < MST_DATCHN_NUMS; j++) begin
                    if ((wr_datbuf[i].wdat_srcid == wdata_info[j].wdat_srcid) &&
                        (wr_datbuf[i].wdat_tgtid == wdata_info[j].wdat_tgtid) &&
                        (wr_datbuf[i].wdat_txnid == wdata_info[j].wdat_txnid)) begin
                        datbuf_match_ptr = i;
                        match_flag = 1;
                        wrchn_idx = j;
                        disable u_match_entry;
                    end
                end
            end
        end
    end

    always_comb begin
        datbuf_dealloc_ptr = 0;
        if (wrdbuf_valid) begin
            for (int i = 0; i < WRDATBUF_DEPTH; i++) begin: u_find_dealloc
                if ((wrdbuf_req.wrreq_srcid == wr_datbuf[i].wrreq_srcid) &&
                    (wrdbuf_req.wrreq_tgtid == wr_datbuf[i].wrreq_tgtid) &&
                    (wrdbuf_req.wrreq_txnid == wr_datbuf[i].wrreq_txnid)) begin
                    datbuf_dealloc_ptr = i;
                    disable u_find_dealloc;
                end 
            end
        end
    end

    always_comb begin
        datbuf_empty_idx = 0;
        for (int i = 0; i < WRDATBUF_DEPTH; i++) begin: u_find_entry;
            if (wr_datbuf_valid[i] == 0) begin
                datbuf_empty_idx = i;
                disable u_find_entry;
            end
        end
    end

    assign datbuf_alloc_ptr = match_flag ? datbuf_match_ptr : datbuf_empty_idx;

    generate

        for (genvar idx = 0; idx < WRDATBUF_DEPTH; idx++) begin

            assign first_alloc[idx] = |wr_datbuf[idx].wdat_srcid;

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    wr_datbuf[idx].wdat_srcid                   <= 'd0;
                    wr_datbuf[idx].wdat_tgtid                   <= 'd0;
                    wr_datbuf[idx].wdat_txnid                   <= 'd0;
                end else if () begin
                    wr_datbuf[idx].wdat_srcid                   <= 'd0;
                    wr_datbuf[idx].wdat_tgtid                   <= 'd0;
                    wr_datbuf[idx].wdat_txnid                   <= 'd0;
                end else if (first_alloc[idx] && (idx == datbuf_alloc_ptr)) begin
                    wr_datbuf[idx].wdat_srcid                   <= wdata_info[wrchn_idx].wdat_srcid;
                    wr_datbuf[idx].wdat_tgtid                   <= wdata_info[wrchn_idx].wdat_tgtid;
                    wr_datbuf[idx].wdat_txnid                   <= wdata_info[wrchn_idx].wdat_txnid;
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    wr_datbuf[idx].wdat_data                    <= 'd0;
                    wr_datbuf[idx].wdat_be                      <= 'd0;
                end else if (first_alloc[idx] && (idx == datbuf_alloc_ptr)) begin
                    case (wdata_info.wdat_dataid)
                        `FLIT0_ENC: begin
                            wr_datbuf[idx].wdat_data[`FLIT0]    <= wdata_info[wrchn_idx].wdat_data;
                            wr_datbuf[idx].wdat_be[`FLIT0]      <= wdata_info[wrchn_idx].wdat_be;
                        end
                        `FLIT1_ENC: begin
                            wr_datbuf[idx].wdat_data[`FLIT1]    <= wdata_info[wrchn_idx].wdat_data;
                            wr_datbuf[idx].wdat_be[`FLIT1]      <= wdata_info[wrchn_idx].wdat_be;
                        end
                        `FLIT2_ENC: begin
                            wr_datbuf[idx].wdat_data[`FLIT2]    <= wdata_info[wrchn_idx].wdat_data;
                            wr_datbuf[idx].wdat_be[`FLIT2]      <= wdata_info[wrchn_idx].wdat_be;
                        end
                        `FLIT3_ENC: begin
                            wr_datbuf[idx].wdat_data[`FLIT3]    <= wdata_info[wrchn_idx].wdat_data;
                            wr_datbuf[idx].wdat_be[`FLIT3]      <= wdata_info[wrchn_idx].wdat_be;
                        end
                        default: begin
                            datid_unk[idx]                      <= 1'b1;
                        end
                    endcase
                end
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (!rstn) begin 
            glbsram_wrreq.req_addr                              <= 'd0;
            glbsram_wrreq.req_rw                                <= 'd0;
            glbsram_wrreq.req_wrdata                            <= 'd0;
            glbsram_wrreq.req_be                                <= 'd0;
            glbsram_wrreq.req_sec_id                            <= 'd0;
        end else if (wrdbuf_valid) begin
            glbsram_wrreq.req_addr                              <= wrdbuf_req.wrreq_addr;
            glbsram_wrreq.req_rw                                <= 1'b1;
            glbsram_wrreq.req_wrdata                            <= wr_datbuf[datbuf_dealloc_ptr].wdat_data;
            glbsram_wrreq.req_be                                <= wr_datbuf[datbuf_dealloc_ptr].wdat_be;
            glbsram_wrreq.req_sec_id                            <= wrdbuf_req.wrreq_secvec;
        end
    end

    always_ff @(posedge clk) begin
        if (!rstn) begin
            glbsram_wrvalid                                     <= 1'b0;
        end else begin
            glbsram_wrvalid                                     <= wrdbuf_valid;
        end
    end
    


endmodule