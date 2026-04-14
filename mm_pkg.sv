//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================



 package mm_pkg;
    parameter REQ_OST               = 64,
    parameter WR_OST                = 64,
    parameter RD_OST                = 64,
    parameter NID_W                 = 11,
    parameteR ADDR_WIDTH            = 60,
    parameter MST_NUMS              = 1,
    parameter MST_REQ_W             = 131,
    parameter MST_RSP_W             = 52,
    parameter MST_DAT_W             = 330, // 256bit data
    parameter MST_REQCHN_NUMS       = 1,
    parameter MST_RSPCHN_NUMS       = 2,
    parameter MST_DATCHN_NUMS       = 1

    parameter TXNID_W = 12;
    parameter ORDER_W = 2;
    parameter PCRDTYPE_W = 4;
    parameter REQOPCODE_W = 4;
    parameter SIZE_W = 4;
    parameter SECVEC_W = 4;
    
    parameter DBID_W = 12;
    parameter RSPOPCODE_W = 3;

    parameter DATOPCODE_W = 2;
    parameter DATA_W = 256;
    parameter DATAID_W = 4;
    parameter DATCNT_W = 2;
    paraemter BE_W = DATA_W / 8;
    parameteR RDDATA_W = DATA_W * 4;

    parameter DATALINE_W = 1024; // 128B
    parameter DATALINEBE_W = DATALINE_W / 8;

    parameter PTR_W = $clog2(REQ_OST) + 1;
    parameter RDPTR_W = $clog2(RD_OST) + 1;

    // DATAID encode
    `define FLIT0_ENC   4'b0000;
    `define FLIT1_ENC   4'b0010;
    `define FLIT2_ENC   4'b0100;
    `define FLIT3_ENC   4'b0110;

    `define FLIT0       255:0;
    `define FLIT1       511:256;
    `define FLIT2       767:512;
    `define FLIT3       1023:768;

    // TBD 
    // REQ/RSP/DAT_OP means opcode field in relative TYPE
    `define REQ_OP
    `define RSP_OP
    `define DAT_OP     
    `define OP_READNOSNP 'h4
    `define OP_WRITENOSNPPTL 'h1c
    `define OP_WRITENOSNPFULL 'h1d
    `define OP_RETRYACK 'h3
    `define OP_COMP 'h4
    `define OP_COMPDBIDRESP 'h5
    `define OP_DBIDRESP 'h6
    `define OP_PCRDGRANT 'h7
    `define OP_READRECEIPT 'h8
    `define OP_COMPDATA 'h4
    `define OP_NCBWRDATA 'h3

    typedef struct packed {
        logic [NID_W-1:0]                   req_srcid;
        logic [NID_W-1:0]                   req_tgtid;
        logic [NID_W-1:0]                   req_addr;
        logic [TXNID_W-1:0]                 req_txnid;
        logic [ORDER_W-1:0]                 req_order;
        logic                               req_allowretry;
        logic [REQOPCODE_W-1:0]             req_opcode;
        logic [SIZE_W-1:0]                  req_size;
        logic [BE_W-1:0]                    req_be;
        logic [SECVEC_W-1:0]                req_secvec;
        logic [DBID_W-1:0]                  req_dbid;
        logic [4:0]                         req_pkt_num; // 512B with 32B data_w
    } req_info_t;

    typedef struct packed {
        logic [NID_W-1:0]                   rsp_srcid;
        logic [NID_W-1:0]                   rsp_tgtid;
        logic [TXNID_W-1:0]                 rsp_txnid;
        logic [DBID_W-1:0]                  rsp_dbid;
        logic [PCRDTYPE_W-1:0]              rsp_pcrdtype;
        logic [RSPOPCODE_W-1:0]             rsp_opcode;
    } rsp_info_t;

    typedef struct packed {
        logic [NID_W-1:0]                   wdat_srcid;
        logic [NID_W-1:0]                   wdat_tgtid;
        logic [TXNID_W-1:0]                 wdat_txnid;
        // logic [DATOPCODE_W-1:0]             wdat_opcode;
        logic [DATALINE_W-1:0]              wdat_data;
        logic [DATALINEBE_W-1:0]            wdat_be;
        logic [DATAID_W-1:0]                wdat_dataid;
        logic [DATCNT_W-1:0]                wdat_datacnt;
    } wdata_info_t;

    typedef struct packed {
        logic [NID_W-1:0]                   rdat_srcid;
        logic [NID_W-1:0]                   rdat_tgtid; // invalid at CompData
        logic [TXNID_W-1:0]                 rdat_txnid;
        logic [DBID_W-1:0]                  rdat_dbid;
        logic [DATOPCODE_W-1:0]             rdat_opcode;
        logic [DATA_W-1:0]                  rdat_data;
        logic [DATAID_W-1:0]                rdat_dataid;
    } rdata_info_t;

    typedef struct packed {
        logic [NID_W-1:0]                   wrreq_srcid;
        logic [NID_W-1:0]                   wrreq_tgtid;
        logic [ADDR_WIDTH-1:0]              wrreq_addr;   
        logic [SIZE_W-1:0]                  wrreq_size;
        logic [DBID_W-1:0]                  wrreq_dbid;
        logic [TXNID_W-1:0]                 wrreq_txnid;  
        logic [SECVEC_W-1:0]                wrreq_secvec;
    } wrreq_t;

    typedef struct packed {
        logic [NID_W-1:0]                   rdreq_srcid;     
        logic [NID_W-1:0]                   rdreq_tgtid;
        logic [ADDR_WIDTH-1:0]              rdreq_addr;   
        logic [SIZE_W-1:0]                  rdreq_size;
        logic [ORDER_W-1:0]                 rdreq_order;
        logic [TXNID_W-1:0]                 rdreq_txnid;                               
    } rdreq_t;

    typedef struct packed {
        rdreq_t                             rdreq;
        logic [2:0]                         dut_dat_nums;    
        logic [RDPTR_W-1:0]                 nxt_ptr; // ptr to next ordered dat
        logic                               head;
    } rdreq_list_t;

    typedef union packed {
        logic [SECVEC_W-1:0]                req_secvec;  
        logic [SECVEC_W-1:0]                req_mst_idx;      
    } sec_id_u;

    typedef struct packed {
        logic [NID_W-1:0]                   req_addr;
        logic                               req_rw;
        logic [DATA_W-1:0]                  req_wrdata;
        logic [BE_W-1:0]                    req_be;            
        sec_id_u                            req_sec_id;                    
    } req_upld_t;

    typedef struct packed {
        logic [RDDATA_W-1:0]                req_rddata;         
        logic [SECVEC_W-1:0]                req_mst_idx;                        
    } dat_upld_t;

    typedef struct packed {
        logic [NID_W-1:0]                   req_srcid;
        logic [NID_W-1:0]                   req_tgtid;
        logic [NID_W-1:0]                   req_addr;
        logic [TXNID_W-1:0]                 req_txnid;
        logic [ORDER_W-1:0]                 req_order;
        logic                               req_allowretry;
        logic [REQOPCODE_W-1:0]             req_opcode;
        logic [SIZE_W-1:0]                  req_size;
        logic [BE_W-1:0]                    req_be;
        logic [SECVEC_W-1:0]                req_secvec;
        logic [DBID_W-1:0]                  req_dbid;
        logic [4:0]                         req_pkt_num; // 512B with 32B data_w
        logic [4:0]                         req_pkt_get;
    } req_entry_t;

    function [PTR_W-1:0] get_first_pos(logic [REQ_OST-1:0] buff_stat, bit rw);
        logic stop;
        logic [REQ_OST-1:0] ptr;
        stop = 0;
        ptr = {PTR_W{rw}};
        for (int i = 0; i < REQ_OST; i++) begin
            if ((buff_stat[0] == rw) && (~stop)) begin
                stop = 1;
                ptr = i;
            end
            buff_stat = buff_stat >> 1;
        end
        get_first_pos = ptr;

    endfunction

    function req_info_t req_flit2struct(logic [MST_REQ_W-1:0] req_flit);
        req_info_t req_info;
            req_info.req_srcid      = req_flit[];
            req_info.req_tgtid      = req_flit[];
            req_info.req_addr       = req_flit[];
            req_info.req_txnid      = req_flit[];
            req_info.req_order      = req_flit[];
            req_info.req_allowretry = req_flit[];
            req_info.req_opcode     = req_flit[];
            req_info.req_size       = req_flit[];
            req_info.req_be         = req_flit[];
            req_info.req_secvec     = req_flit[];
            req_info.req_dbid       = '0;
            req_info.req_pkg_end    = '0;
        return req_info;
    endfunction

    function rsp_info_t rsp_flit2struct(logic [MST_RSP_W-1:0] rsp_flit);
        rsp_info_t rsp_info;
            rsp_info.rsp_srcid      = rsp_flit[];
            rsp_info.rsp_tgtid      = rsp_flit[];
            rsp_info.rsp_txnid      = rsp_flit[];
            rsp_info.rsp_dbid       = rsp_flit[];
            rsp_info.rsp_pcrdtype   = rsp_flit[];
            rsp_info.rsp_opcode     = rsp_flit[];
        return rsp_info;
    endfunction

    function wdata_info_t wdat_flit2struct(logic [MST_DAT_W-1:0] dat_flit);
        wdata_info_t wdata_info;
            wdata_info.wdat_srcid   = dat_flit[];
            wdata_info.wdat_tgtid   = dat_flit[];
            wdata_info.wdat_txnid   = dat_flit[];
            wdata_info.wdat_data    = dat_flit[];
            wdata_info.wdat_be      = dat_flit[];
            wdata_info.wdat_dataid  = dat_flit[];
            wdata_info.wdat_datacnt = dat_flit[];
        return wdata_info;
    endfunction

    function rdata_info_t rdat_flit2struct(logic [MST_DAT_W-1:0] dat_flit);
        rdata_info_t rdata_info;
            rdata_info.rdat_srcid   = dat_flit[];
            rdata_info.rdat_tgtid   = dat_flit[];
            rdata_info.rdat_txnid   = dat_flit[];
            rdata_info.rdat_data    = dat_flit[];
            rdata_info.rdat_dataid  = dat_flit[];
            rdata_info.rdat_dbid    = dat_flit[];
            rdata_info.rdat_opcode  = dat_flit[];
        return rdata_info;
    endfunction


 endpackage