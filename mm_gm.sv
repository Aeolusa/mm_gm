//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================


module mm_gm 
import mm_pkg::*;
#(
    parameter NID_W             = 11,
    parameter ADDR_WIDTH        = 60,
    parameter SM_NUMS           = 1,
    parameter SM_REQ_W          = 131,
    parameter SM_RSP_W          = 52,
    parameter SM_DAT_W          = 330,
    parameter SM_REQCHN_NUMS    = 1,
    parameter SM_RSPCHN_NUMS    = 2,
    parameter SM_DATCHN_NUMS    = 1,
    parameter HST_REQ_W         = 1,
    parameter HST_RSP_W         = 1,
    parameter HST_DAT_W         = 1,
    parameter HST_REQCHN_NUMS   = 1,
    parameter HST_RSPCHN_NUMS   = 2,
    parameter HST_DATCHN_NUMS   = 1,
    parameter TS_REQ_W          = 1,
    parameter TS_RSP_W          = 1,
    parameter TS_DAT_W          = 1,
    parameter TS_REQCHN_NUMS    = 1,
    parameter TS_RSPCHN_NUMS    = 2,
    parameter TS_DATCHN_NUMS    = 1,
    parameter BLIT_REQ_W        = 1,
    parameter BLIT_RSP_W        = 1,
    parameter BLIT_DAT_W        = 1,
    parameter BLIT_REQCHN_NUMS  = 1,
    parameter BLIT_RSPCHN_NUMS  = 2,
    parameter BLIT_DATCHN_NUMS  = 1

) (
    input   bit                                                             clk,
    input   bit                                                             rstn,
    // SM
    input   logic [SM_NUMS-1:0][SM_REQCHN_NUMS-1:0][SM_REQ_W-1:0]           sm_txreq_flit,
    input   logic [SM_NUMS-1:0][SM_REQCHN_NUMS-1:0]                         sm_txreq_flitv,
    input   logic [SM_NUMS-1:0][SM_RSPCHN_NUMS-1:0][SM_RSP_W-1:0]           sm_txrsp_flit,
    input   logic [SM_NUMS-1:0][SM_RSPCHN_NUMS-1:0]                         sm_txrsp_flitv,
    input   logic [SM_NUMS-1:0][SM_RSPCHN_NUMS-1:0][SM_RSP_W-1:0]           sm_rxrsp_flit,
    input   logic [SM_NUMS-1:0][SM_REQCHN_NUMS-1:0]                         sm_rxrsp_flitv,
    input   logic [SM_NUMS-1:0][SM_DATCHN_NUMS-1:0][SM_DAT_W-1:0]           sm_txdat_flit,
    input   logic [SM_NUMS-1:0][SM_DATCHN_NUMS-1:0]                         sm_txdat_flitv,
    input   logic [SM_NUMS-1:0][SM_DATCHN_NUMS-1:0][SM_DAT_W-1:0]           sm_rxdat_flit,
    input   logic [SM_NUMS-1:0][SM_DATCHN_NUMS-1:0]                         sm_rxdat_flitv,
    // HOST
    input   logic [HST_REQCHN_NUMS-1:0][HST_REQ_W-1:0]         		        host_txreq_flit,
    input   logic [HST_REQCHN_NUMS-1:0]                        		        host_txreq_flitv,
    input   logic [HST_RSPCHN_NUMS-1:0][HST_RSP_W-1:0]         		        host_txrsp_flit,
    input   logic [HST_RSPCHN_NUMS-1:0]                        		        host_txrsp_flitv,
    input   logic [HST_RSPCHN_NUMS-1:0][HST_RSP_W-1:0]         		        host_rxrsp_flit,
    input   logic [HST_RSPCHN_NUMS-1:0]                        		        host_rxrsp_flitv,
    input   logic [HST_DATCHN_NUMS-1:0][HST_DAT_W-1:0]         		        host_txdat_flit,
    input   logic [HST_DATCHN_NUMS-1:0]                        		        host_txdat_flitv,
    input   logic [HST_DATCHN_NUMS-1:0][HST_DAT_W-1:0]         		        host_rxdat_flit,
    input   logic [HST_DATCHN_NUMS-1:0]                        		        host_rxdat_flitv,
    // TS
    input   logic [TS_REQCHN_NUMS-1:0][TS_REQ_W-1:0]         		        ts_txreq_flit,
    input   logic [TS_REQCHN_NUMS-1:0]                        		        ts_txreq_flitv,
    input   logic [TS_RSPCHN_NUMS-1:0][TS_RSP_W-1:0]         		        ts_txrsp_flit,
    input   logic [TS_RSPCHN_NUMS-1:0]                        		        ts_txrsp_flitv,
    input   logic [TS_RSPCHN_NUMS-1:0][TS_RSP_W-1:0]         		        ts_rxrsp_flit,
    input   logic [TS_RSPCHN_NUMS-1:0]                        		        ts_rxrsp_flitv,
    input   logic [TS_DATCHN_NUMS-1:0][TS_DAT_W-1:0]         		        ts_txdat_flit,
    input   logic [TS_DATCHN_NUMS-1:0]                        		        ts_txdat_flitv,
    input   logic [TS_DATCHN_NUMS-1:0][TS_DAT_W-1:0]         		        ts_rxdat_flit,
    input   logic [TS_DATCHN_NUMS-1:0]                        		        ts_rxdat_flitv,
    // BLIT
    input   logic [BLIT_REQCHN_NUMS-1:0][BLIT_REQ_W-1:0]         		    blit_txreq_flit,
    input   logic [BLIT_REQCHN_NUMS-1:0]                        		    blit_txreq_flitv,
    input   logic [BLIT_RSPCHN_NUMS-1:0][BLIT_RSP_W-1:0]         		    blit_txrsp_flit,
    input   logic [BLIT_RSPCHN_NUMS-1:0]                        		    blit_txrsp_flitv,
    input   logic [BLIT_RSPCHN_NUMS-1:0][BLIT_RSP_W-1:0]         		    blit_rxrsp_flit,
    input   logic [BLIT_RSPCHN_NUMS-1:0]                        		    blit_rxrsp_flitv,
    input   logic [BLIT_DATCHN_NUMS-1:0][BLIT_DAT_W-1:0]         		    blit_txdat_flit,
    input   logic [BLIT_DATCHN_NUMS-1:0]                        		    blit_txdat_flitv,
    input   logic [BLIT_DATCHN_NUMS-1:0][BLIT_DAT_W-1:0]         		    blit_rxdat_flit,
    input   logic [BLIT_DATCHN_NUMS-1:0]                        		    blit_rxdat_flitv
);


    // ------------------------------- frontend ---------------------------------

    // SM alloc
    genvar sm_idx;
    generate: sm_alloc
        for (sm_idx = 0; sm_idx < SM_NUMS; sm_idx++) begin
            mm_allocator #(.mst_idx(sm_idx)) u_sm_allocator (
                .clk(),
                .rstn(),
                // SM
                .txreq_flit(),
                .txreq_flitv(),
                .txrsp_flit(),
                .txrsp_flitv(),
                .rxrsp_flit(),
                .rxrsp_flitv(),
                .txdat_flit(),
                .txdat_flitv(),
                .rxdat_flit(),
                .rxdat_flitv(),
                // To glb sram
                .glbsram_rdreq(),
                .glbsram_rdvalid(),
                .glbsram_data(),
                .glbsram_data_valid(),
                .glbsram_wrreq(),
                .glbsram_wrvalid()
            );
        end
    endgenerate

    // HOST alloc
    mm_allocator #(.mst_idx(SM_NUMS)) u_host_allocator (
        .clk(),
        .rstn(),
        // SM
        .txreq_flit(),
        .txreq_flitv(),
        .txrsp_flit(),
        .txrsp_flitv(),
        .rxrsp_flit(),
        .rxrsp_flitv(),
        .txdat_flit(),
        .txdat_flitv(),
        .rxdat_flit(),
        .rxdat_flitv(),
        // To glb sram
        .glbsram_rdreq(),
        .glbsram_rdvalid(),
        .glbsram_data(),
        .glbsram_data_valid(),
        .glbsram_wrreq(),
        .glbsram_wrvalid()
    );

    // TS alloc
    mm_allocator #(.mst_idx(SM_NUMS + 1)) u_ts_allocator (
        .clk(),
        .rstn(),
        // SM
        .txreq_flit(),
        .txreq_flitv(),
        .txrsp_flit(),
        .txrsp_flitv(),
        .rxrsp_flit(),
        .rxrsp_flitv(),
        .txdat_flit(),
        .txdat_flitv(),
        .rxdat_flit(),
        .rxdat_flitv(),
        // To glb sram
        .glbsram_rdreq(),
        .glbsram_rdvalid(),
        .glbsram_data(),
        .glbsram_data_valid(),
        .glbsram_wrreq(),
        .glbsram_wrvalid()
    );

    // ------------------------------- backend ---------------------------------

endmodule
