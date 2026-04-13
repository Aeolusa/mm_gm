//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================

// ASSUME: REQ chn will be constraint to ONE
module mm_allocator 
import mm_pkg::*;
(
    input   bit                                                             clk,
    input   bit                                                             rstn,
    // SM
    input   logic [MST_REQCHN_NUMS-1:0][MST_REQ_W-1:0]                      txreq_flit,
    input   logic [MST_REQCHN_NUMS-1:0]                                     txreq_flitv,
    input   logic [MST_RSPCHN_NUMS-1:0][MST_RSP_W-1:0]                      txrsp_flit,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     txrsp_flitv,
    input   logic [MST_RSPCHN_NUMS-1:0][MST_RSP_W-1:0]                      rxrsp_flit,
    input   logic [MST_RSPCHN_NUMS-1:0]                                     rxrsp_flitv,
    input   logic [MST_DATCHN_NUMS-1:0][MST_DAT_W-1:0]                      txdat_flit,
    input   logic [MST_DATCHN_NUMS-1:0]                                     txdat_flitv,
    input   logic [MST_DATCHN_NUMS-1:0][MST_DAT_W-1:0]                      rxdat_flit,
    input   logic [MST_DATCHN_NUMS-1:0]                                     rxdat_flitv,

    // To glb sram
    output  req_upld_t                                                      glbsram_rdreq,
    output  logic                                                           glbsram_rdvalid,
    input   dat_upld_t                                                      glbsram_data,
    input   logic                                                           glbsram_data_valid,
    output  req_upld_t                                                      glbsram_wrreq,
    output  logic                                                           glbsram_wrvalid
);

    localparam ReadNoSnp        = 4'h1 ;
    localparam WriteNoSnpPtl    = 4'h3 ;
    localparam WriteNoSnpFull   = 4'h2 ;
    localparam RetryAck         = 3'h1 ;
    localparam PCrdGrant        = 3'h2 ;
    localparam DBIDResp         = 3'h3 ;
    localparam Comp             = 3'h4 ;
    localparam CompDBIDResp     = 3'h5 ;
    localparam ReadReceipt      = 3'h6 ;
    localparam CompData         = 2'h1 ;
    localparam NCBWrData        = 2'h2 ;
    
    req_info_t [MST_REQCHN_NUMS-1:0]                        req_info;
    rsp_info_t [MST_RSPCHN_NUMS-1:0]                        rsp_info;
    wdata_info_t [MST_DATCHN_NUMS-1:0]                      wdata_info;
    rdata_info_t [MST_DATCHN_NUMS-1:0]                      rdata_info;

    logic [MST_REQCHN_NUMS-1:0]                             valid_Request;
    logic [MST_REQCHN_NUMS-1:0]                             valid_ReadNoSnp;
    logic [MST_REQCHN_NUMS-1:0]                             valid_WriteNoSnpPtl;
    logic [MST_REQCHN_NUMS-1:0]                             valid_WriteNoSnpFull;
    logic [MST_RSPCHN_NUMS-1:0]                             valid_RetryAck;
    logic [MST_RSPCHN_NUMS-1:0]                             valid_Comp;
    logic [MST_RSPCHN_NUMS-1:0]                             valid_CompDBIDResp;
    logic [MST_RSPCHN_NUMS-1:0]                             valid_DBIDResp;
    logic [MST_RSPCHN_NUMS-1:0]                             valid_ReadReceipt;
    logic [MST_DATCHN_NUMS-1:0]                             valid_CompData;
    logic [MST_DATCHN_NUMS-1:0]                             valid_NCBWrData;

    rdreq_t                                                 rddbuf_req;
    logic                                                   rddbuf_valid;
    wrreq_t                                                 wrdbuf_req;
    logic                                                   wrdbuf_valid;
    generate
        for (genvar i = 0; i < MST_REQCHN_NUMS; i++) begin: u_req_intf
            assign valid_Request[i]         = txreq_flitv[i];
            assign valid_ReadNoSnp[i]       = txreq_flitv[i] && (txreq_flit[i][`REQ_OP] == `OP_READNOSNP);
            assign valid_WriteNoSnpPtl[i]   = txreq_flitv[i] && (txreq_flit[i][`REQ_OP] == `OP_WRITENOSNPPTL);
            assign valid_WriteNoSnpFull[i]  = txreq_flitv[i] && (txreq_flit[i][`REQ_OP] == `OP_WRITENOSNPFULL);

            assign req_info[i]              = req_flit2struct(txreq_flit[i]);
        end

        for (genvar i = 0; i < MST_RSPCHN_NUMS; i++) begin: u_rsp_intf
            assign valid_RetryAck[i]        = rxrsp_flitv[i] && (rxrsp_flit[i][`RSP_OP] == `OP_RETRYACK);
            assign valid_Comp[i]            = rxrsp_flitv[i] && (rxrsp_flit[i][`RSP_OP] == `OP_COMP);
            assign valid_CompDBIDResp[i]    = rxrsp_flitv[i] && (rxrsp_flit[i][`RSP_OP] == `OP_COMPDBIDRESP);
            assign valid_DBIDResp[i]        = rxrsp_flitv[i] && (rxrsp_flit[i][`RSP_OP] == `OP_DBIDRESP)
            assign valid_ReadReceipt[i]     = rxrsp_flitv[i] && (rxrsp_flit[i][`RSP_OP] == `OP_READRECEIPT);

            assign rsp_info[i]              = rsp_flit2struct(rxrsp_flit[i]);
        end

        for (genvar i = 0; i < MST_DATCHN_NUMS; i++) begin: u_dat_intf
            assign valid_CompData[i]        = rxdat_flitv[i] && (rxdat_flit[i][`DAT_OP] == `OP_COMPDATA);
            assign valid_NCBWrData[i]       = txdat_flitv[i] && (txdat_flit[i][`DAT_OP] == `OP_NCBWRDATA);

            assign wdata_info[i]            = wdat_flit2struct(txdat_flit[i]);
            assign rdata_info[i]            = rdat_flit2struct(rxdat_flit[i]);
        end

     endgenerate

    mm_req u_mm_req(.*);

    mm_rddbuf u_mm_rddbuf(.*);

    mm_wrdbuf u_mm_wrdbuf(.*);
        
endmodule






































    endmodule
