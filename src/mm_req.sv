//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================


// ID match should consider 
// TX/RX.tgtid/srcid info valid? 
// Check against SPEC

// One Store scenerio should be consider
// req_entry.wr(ie, TXNID=e) is clr when all wrdata is collected, 
// but when mst received DBID, it can send the same TXNID
// req_entry's old wr(TXNID=e) still active

// WR Req dispatch depends on DBID

module mm_req 
import mm_pkg::*;
(
    input   bit                                                             clk,
    input   bit                                                             rstn,
    // op
    input   logic [MST_REQCHN_NUMS-1:0]                                     valid_Request,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     valid_RetryAck,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     valid_Comp,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     valid_CompDBIDResp,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     valid_DBIDResp,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     valid_ReadReceipt,
    input   logic [MST_DATCHN_NUMS-1:0]                                     valid_CompData,
    input   logic [MST_DATCHN_NUMS-1:0]                                     valid_NCBWrData,
    input   logic [MST_REQCHN_NUMS-1:0]                                     valid_ReadNoSnp,
    // trans info
    input   req_info_t [MST_REQCHN_NUMS-1:0]                                req_info,
    input   rsp_info_t [MST_RSPCHN_NUMS-1:0]                                rsp_info,
    input   wdata_info_t [MST_DATCHN_NUMS-1:0]                              wdata_info,
    input   rdata_info_t [MST_DATCHN_NUMS-1:0]                              rdata_info,
    // to databuf
    output  rdreq_t                                                         rddbuf_req,
    output  logic                                                           rddbuf_valid;      
    output  wrreq_t                                                         wrdbuf_req,
    output  logic                                                           wrdbuf_valid
);

    localparam REQCHN_W = $clog2(MST_REQCHN_NUMS);
    localparam RSPCHN_W = $clog2(MST_RSPCHN_NUMS);

    // pq
    req_entry_t     [REQ_OST-1:0]                                           req_entry;
    dat_entry_t     [REQ_OST-1:0]                                           dat_entry;
    pcrd_entry_t    [REQ_OST-1:0]                                           pcrd_entry;
    logic           [REQ_OST-1:0]                                           reqentry_valid;
    logic           [REQ_OST-1:0]                                           reqentry_set;
    logic           [REQ_OST-1:0]                                           reqentry_clr;

    logic           [REQ_OST-1:0][MST_RSPCHN_NUMS-1:0]                      rsp_retry;
    logic           [REQ_OST-1:0][MST_RSPCHN_NUMS-1:0]                      rsp_comp;               
    logic           [REQ_OST-1:0][MST_RSPCHN_NUMS-1:0]                      rsp_compdbid;
    logic           [MST_RSPCHN_NUMS-1:0]                                   valid_dbid;
    logic           [REQ_OST-1:0][MST_RSPCHN_NUMS-1:0]                      rsp_dbid;
    logic           [RSPCHN_W-1:0]                                          dbid_update_ptr;
    logic           [REQ_OST-1:0][MST_RSPCHN_NUMS-1:0]                      rsp_readreceipt;
    logic           [REQ_OST-1:0]                                           readreceipt_en;
    logic           [REQ_OST-1:0]                                           wrreq_data_collected;
    logic           [REQ_OST-1:0]                                           wrreq_data_enough;
    logic           [REQ_OST-1:0][MST_DATCHN_NUMS-1:0]                      wrreq_ncbdata;
    
    // OUT wire
    rdreq_t                                                                 rdreq;
    wrreq_t                                                                 wrreq;

    logic           [REQCHN_W-1:0]                                          valid_reqidx;
    logic           [PTR_W-1:0]                                             reqentry_wrptr;
    logic           [PTR_W-1:0]                                             reqentry_rdptr;
    
    // Indicate corresponding entry's rsp state
    logic           [REQ_OST-1:0]           					            rsp_assert_combined; 
    logic           [REQ_OST-1:0]           					            comp_asserted;
    logic           [REQ_OST-1:0]           					            compdbid_asserted;
    logic           [REQ_OST-1:0]           					            dbid_asserted;

    logic           [PTR_W-1:0]             					            req_wrdispatch_ptr;
    logic           [PTR_W-1:0]             					            req_rddealloc_ptr;

    logic           [REQ_OST-1:0]           					            wrreq_valid;   
    logic           [REQ_OST-1:0]           					            rdreq_valid;    
    
    logic           [MST_REQCHN_NUMS-1:0]          					        rd_noorder; 
    rdreq_t                                 					            noorder_rdbuf;
    logic                                   					            noorder_rdvalid;
    logic                                   					            orderrd_content;
    logic                                   					            orderrd_contentd1;
    rdreq_t                                 					            noorder_rdbufd1;                         

    assign rddbuf_valid                                     = |rdreq_valid | noorder_rdvalid;
    assign wrdbuf_valid                                     = |wrreq_valid;
    assign rddbuf_req                                       = |rdreq_valid ? rdreq : noorder_rdbufd1;
    assign wrdbuf_req                                       = wrreq[req_wrdispatch_ptr];
    assign rsp_assert_combined                              = compdbid_asserted |
                                                              dbid_asserted;
    assign valid_dbid                                       = valid_DBIDResp | valid_CompDBIDResp;
        
    assign reqentry_wrptr                                   = get_first_pos(reqentry_valid, 1'b0);
    assign req_wrdispatch_ptr                               = get_first_pos(dbid_asserted, 1'b1);
    assign req_rddealloc_ptr                                = get_first_pos(readreceipt_en, 1'b1);
    assign valid_reqidx                                     = get_first_pos(valid_Request, 1'b1);
    assign dbid_update_ptr                                  = get_first_pos(valid_dbid, 1'b1);

    always_ff @(posedge clk) begin
        if (orderrd_content) begin
            noorder_rdbufd1                                 <= noorder_rdbuf;
        end
    end 

    assign orderrd_content                                  = |rd_noorder & rdreq_valid;

    always_ff @(posedge clk) begin
        orderrd_contentd1                                   <= orderrd_content;
    end

    always_comb begin
        rdreq                                               = '0;
        if (|readreceipt_en) begin
            rdreq                                           = req_entry[req_rddealloc_ptr];
        end
    end

    always_comb begin
        wrreq                                               = '0;
        if (|wrreq_data_collected) begin
            wrreq                                           = req_entry[req_wrdispatch_ptr];
        end
    end

    // Content condition
    // Noorder Rd + Ordered Rd
    // Ordered Rd dispatch at cycle0, Noorder Rd dispatch at cycle1
    always_ff @(posedge clk) begin
        if (!rstn) begin
            noorder_rdvalid                                 <= 1'b0;
        end else if (orderrd_contentd1) begin
            noorder_rdvalid                                 <= 1'b1;
        end else if (|rd_noorder && ~rddbuf_valid) begin
            noorder_rdvalid                                 <= 1'b1;
        end else begin
            noorder_rdvalid                                 <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rstn) begin
            noorder_rdbuf.rdreq_srcid                       <= 'd0;
            noorder_rdbuf.rdreq_tgtid                       <= 'd0;
            noorder_rdbuf.rdreq_addr                        <= 'd0;
            noorder_rdbuf.rdreq_txnid                       <= 'd0;
            noorder_rdbuf.rdreq_order                       <= 'd0;
            noorder_rdbuf.rdreq_size                        <= 'd0;
        end else if (|rd_noorder) begin
            noorder_rdbuf.rdreq_srcid                       <= req_info[valid_reqidx].rdreq_srcid;
            noorder_rdbuf.rdreq_tgtid                       <= req_info[valid_reqidx].rdreq_tgtid;
            noorder_rdbuf.rdreq_addr                        <= req_info[valid_reqidx].rdreq_addr;
            noorder_rdbuf.rdreq_txnid                       <= req_info[valid_reqidx].rdreq_txnid;
            noorder_rdbuf.rdreq_order                       <= req_info[valid_reqidx].rdreq_order;
            noorder_rdbuf.rdreq_size                        <= req_info[valid_reqidx].rdreq_size;
        end
    end

    

    generate

        for (genvar idx = 0; idx < MST_REQCHN_NUMS; idx++) begin
            assign rd_noorder[idx]                          = valid_ReadNoSnp[idx] && (req_info[idx].req_order == 0);
        end

        for (genvar idx = 0; idx < REQ_OST; idx++) begin: u_req_entry

            always_comb begin
                reqentry_set[idx]                           = 0;
                if (|valid_Request && (reqentry_wrptr == idx) && ~(|rd_noorder)) begin
                    reqentry_set[idx]                       = 1'b1;
                end
            end                         

            always_comb begin
                reqentry_clr[idx] = 0;
                if (reqentry_valid[idx] &&
                    (wrreq_data_enough[idx] || 
                    readreceipt_en[idx] ||
                    |rsp_retry[idx])
                ) begin
                    reqentry_clr[idx] = 1;
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    req_entry[idx].req_srcid                <= 'd0;
                    req_entry[idx].req_tgtid                <= 'd0;
                    req_entry[idx].req_txnid                <= 'd0;
                    req_entry[idx].req_addr                 <= 'd0;
                    req_entry[idx].req_size                 <= 'd0;
                    req_entry[idx].req_order                <= 'd0;
                    req_entry[idx].req_pkt_num              <= 'd0;
                end else if (reqentry_set[idx]) begin
                    req_entry[idx].req_srcid                <= req_info[valid_reqidx].req_srcid;
                    req_entry[idx].req_tgtid                <= req_info[valid_reqidx].req_tgtid;
                    req_entry[idx].req_txnid                <= req_info[valid_reqidx].req_txnid;
                    req_entry[idx].req_addr                 <= req_info[valid_reqidx].req_addr;
                    req_entry[idx].req_size                 <= req_info[valid_reqidx].req_size;
                    req_entry[idx].req_order                <= req_info[valid_reqidx].req_order;
                    req_entry[idx].req_pkt_num              <= req_info[valid_reqidx].req_pkt_num;
                end
            end  

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    req_entry[idx].req_dbid                 <= 'd0;
                end else if (reqentry_valid[idx] && 
                            (|rsp_dbid[idx] ||
                             |rsp_compdbid[idx])
                        ) begin
                    req_entry[idx].req_dbid[idx]            <= rsp_info[dbid_update_ptr].rsp_dbid;
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    reqentry_valid[idx]                     <= 1'b0;
                end else if (reqentry_clr[idx]) begin
                    reqentry_valid[idx]                     <= 1'b0;
                end else if (reqentry_set[idx]) begin
                    reqentry_valid[idx]                     <= 1'b1;
                end
            end   
        end


        for (genvar i = 0; i < REQ_OST; i++) begin: u_rsp_entry
            for (genvar j = 0; j < MST_RSPCHN_NUMS; j++) begin
                assign rsp_retry[i][j]                      = valid_RetryAck[j] && 
                                                              (req_entry[i].req_tgtid == rsp_info[j].rsp_srcid) &&
                                                              (req_entry[i].req_txnid == rsp_info[j].rsp_txnid) &&
                                                              (req_entry[i].req_srcid == rsp_info[j].rsp_tgtid) &&
                                                              ~rsp_assert_combined[i];

                assign rsp_comp[i][j]                       = valid_Comp[j] && 
                                                              (req_entry[i].req_tgtid == rsp_info[j].rsp_srcid) &&
                                                              (req_entry[i].req_txnid == rsp_info[j].rsp_txnid) &&
                                                              (req_entry[i].req_srcid == rsp_info[j].rsp_tgtid);
                
                assign rsp_compdbid[i][j]                   = valid_CompDBIDResp[j] &&
                                                              (req_entry[i].req_tgtid == rsp_info[j].rsp_srcid) &&
                                                              (req_entry[i].req_txnid == rsp_info[j].rsp_txnid) &&
                                                              (req_entry[i].req_srcid == rsp_info[j].rsp_tgtid) &&
                                                              ~rsp_assert_combined[i];

                assign rsp_dbid[i][j]                       = valid_DBIDResp[j] &&
                                                              (req_entry[i].req_tgtid == rsp_info[j].rsp_srcid) &&
                                                              (req_entry[i].req_txnid == rsp_info[j].rsp_txnid) &&
                                                              (req_entry[i].req_srcid == rsp_info[j].rsp_tgtid) &&
                                                              ~rsp_assert_combined[i];
                
                assign rsp_readreceipt[i][j]                = valid_ReadReceipt[j] &&
                                                              (req_entry[i].req_tgtid == rsp_info[j].rsp_srcid) &&
                                                              (req_entry[i].req_txnid == rsp_info[j].rsp_txnid) &&
                                                              (req_entry[i].req_srcid == rsp_info[j].rsp_tgtid) &&
                                                              ~rsp_assert_combined[i];
            end

            assign readreceipt_en[i]                        = |rsp_readreceipt[i];

        end

        for (genvar idx = 0; idx < REQ_OST; idx++) begin: u_dat_entry
        

            assign wrreq_data_collected[idx]                = (compdbid_asserted[idx] || comp_asserted[idx]) &&
                                                              dbid_asserted[idx] &&
                                                              wrreq_data_enough[idx];

            assign wrreq_data_enough[idx]                   = (req_entry[i].req_pkt_num <= req_entry[i].req_pkt_get) &&
                                                              reqentry_valid[i];

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    req_entry[idx].req_pkt_get              <= 'd0;
                end else if (reqentry_clr[idx]) begin
                    req_entry[idx].req_pkt_get              <= 'd0;
                end else if (|wrreq_ncbdata[idx]) begin
                    req_entry[idx].req_pkt_get              <= req_entry[idx].req_pkt_get + 'd1;
                end
            end

            for (genvar dat_chn = 0; dat_chn < MST_DATCHN_NUMS; dat_chn++) begin
                assign wrreq_ncbdata[idx][dat_chn]          = (valid_NCBWrData[dat_chn]) &&
                                                              (req_entry[idx].req_tgtid == wdata_info[dat_chn].wdat_tgtid) &&
                                                              (req_entry[idx].req_dbid  == wdata_info[dat_chn].wdat_txnid) &&
                                                              (req_entry[idx].req_srcid == wdata_info[dat_chn].wdat_srcid) &&
                                                              compdbid_asserted[idx] &&
                                                              dbid_asserted[idx];
            end

        end

        for (genvar idx = 0; idx < REQ_OST; idx++) begin: u_rsp_flag

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    comp_asserted[idx]                      <= 1'b0;
                end else if (reqentry_clr[idx]) begin
                    comp_asserted[idx]                      <= 1'b0;                    
                end else if (|rsp_comp[idx]) begin
                    comp_asserted[idx]                      <= 1'b1;   
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    compdbid_asserted[idx]                  <= 1'b0;
                end else if (reqentry_clr[idx]) begin
                    compdbid_asserted[idx]                  <= 1'b0;                    
                end else if (|rsp_compdbid[idx]) begin
                    compdbid_asserted[idx]                  <= 1'b1;   
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    dbid_asserted[idx]                      <= 1'b0;
                end else if (reqentry_clr[idx]) begin
                    dbid_asserted[idx]                      <= 1'b0;                    
                end else if (|rsp_dbid[idx]) begin
                    dbid_asserted[idx]                      <= 1'b1;   
                end
            end

        end
    endgenerate

    generate 
        for (genvar idx = 0; idx < REQ_OST; idx++) begin: req2dbuf

            always_comb begin
                rdreq_valid[idx]                            = 1'b0;
                if (readreceipt_en[idx]) begin
                    rdreq_valid[idx]                        = 1'b1;
                end
            end 

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    wrreq_valid[idx]                        <= 1'b0;
                end else if (dbid_asserted[idx]) begin
                    wrreq_valid[idx]                        <= 1'b1;
                end
            end 
        end
    endgenerate



        
endmodule






































    endmodule
