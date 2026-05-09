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
    parameter ADDR_WIDTH            = 60,
    parameter MST_NUMS              = 1,
    parameter MST_REQ_W             = 131,
    parameter MST_RSP_W             = 52,
    parameter MST_TXDAT_W           = 330, // 256bit data
    parameter MST_RXDAT_W           = 317, // 256bit data
    parameter MST_REQCHN_NUMS       = 1,
    parameter MST_RSPCHN_NUMS       = 2,
    parameter MST_DATCHN_NUMS       = 1

    parameter TXNID_W               = 12;
    parameter ORDER_W               = 2;
    parameter PCRDTYPE_W            = 4;
    parameter REQOPCODE_W           = 4;
    parameter SIZE_W                = 4;
    parameter SECVEC_W              = 4;
    parameter REQADDR_W             = 54;
    
    parameter DBID_W                = 12;
    parameter RSPOPCODE_W           = 3;
    parameter RSPRESPERR_W          = 2;
    parameter RSPCBUDY_W            = 3;
    parameter RSPPCRDTYPE_W         = 4;

    parameter DATOPCODE_W           = 2;
    parameter DATA_W                = 256;
    parameter DATAID_W              = 4;
    parameter DATCNT_W              = 2;
    parameter BE_W                  = DATA_W / 8;
    parameter RDDATA_W              = DATA_W * 4;
    parameter DATRESPERR_W          = 2;
    parameter TRACETAG_W            = 1;

    parameter DATALINE_W            = 1024; // 128B
    parameter DATALINEBE_W          = DATALINE_W / 8;

    parameter PTR_W                 = $clog2(REQ_OST) + 1;
    parameter RDPTR_W               = $clog2(RD_OST) + 1;

    // REQ Field 
    parameter REQ_TGTID_LSB         = 4;
    parameter REQ_TGTID_MSB         = REQ_TGTID_LSB + NID_W - 1;

    parameter REQ_TXNID_LSB         = REQ_TGTID_MSB + 1;
    parameter REQ_TXNID_MSB         = REQ_TXNID_LSB + TXNID_W - 1;

    parameter REQ_OPCODE_LSB        = REQ_TXNID_MSB + 1;
    parameter REQ_OPCODE_MSB        = REQ_OPCODE_LSB + REQOPCODE_W - 1;

    parameter REQ_SIZE_LSB          = REQ_OPCODE_MSB + 1;
    parameter REQ_SIZE_MSB          = REQ_SIZE_LSB + SIZE_W - 1;

    parameter REQ_SECVEC_LSB        = REQ_SIZE_MSB + 1;
    parameter REQ_SECVEC_MSB        = REQ_SECVEC_LSB + SECVEC_W - 1;

    parameter REQ_ADDR_LSB          = REQ_SECVEC_MSB + 1;
    parameter REQ_ADDR_MSB          = REQ_ADDR_LSB + REQADDR_W - 1;

    parameter REQ_ALLOWRETRY_LSB    = REQ_ADDR_MSB + 1;

    parameter REQ_ORDER_LSB         = REQ_ALLOWRETRY_LSB + PCRDTYPE_W + 1;
    parameter REQ_ORDER_MSB         = REQ_ORDER_LSB + ORDER_W - 1;

    // RSP Field 
    parameter RSP_TGTID_LSB         = 4;
    parameter RSP_TGTID_MSB         = RSP_TGTID_LSB + NID_W - 1;

    parameter RSP_TXNID_LSB         = RSP_TGTID_MSB + 1;
    parameter RSP_TXNID_MSB         = RSP_TXNID_LSB + TXNID_W - 1;

    parameter RSP_OPCODE_LSB        = RSP_TXNID_MSB + 1;
    parameter RSP_OPCODE_MSB        = RSP_OPCODE_LSB + RSPOPCODE_W - 1;

    parameter RSP_DBID_LSB          = RSP_OPCODE_MSB + RSPRESPERR_W + RSPCBUDY_W + 1;
    parameter RSP_DBID_MSB          = RSP_DBID_LSB + DBID_W - 1;

    parameter RSP_PCRDTYPE_LSB      = RSP_DBID_MSB + 1;
    parameter RSP_PCRDTYPE_MSB      = RSP_PCRDTYPE_LSB + PCRDTYPE_W - 1;

    // TXDAT Field
    parameter TXDAT_TGTID_LSB       = 4;
    parameter TXDAT_TGTID_MSB       = TXDAT_TGTID_LSB + NID_W - 1;

    parameter TXDAT_TXNID_LSB       = TXDAT_TGTID_MSB + 1;
    parameter TXDAT_TXNID_MSB       = TXDAT_TXNID_LSB + TXNID_W - 1;

    parameter TXDAT_OPCODE_LSB      = TXDAT_TXNID_MSB + 1;
    parameter TXDAT_OPCODE_MSB      = TXDAT_OPCODE_LSB + DATOPCODE_W - 1;

    parameter TXDAT_DATAID_LSB      = TXDAT_OPCODE_MSB + DATRESPERR_W + 1;
    parameter TXDAT_DATAID_MSB      = TXDAT_DATAID_LSB + DATAID_W - 1;

    parameter TXDAT_DATA_LSB        = TXDAT_DATAID_MSB + 1;
    parameter TXDAT_DATA_MSB        = TXDAT_DATA_LSB + DATA_W - 1;

    parameter TXDAT_BE_LSB          = TXDAT_DATA_MSB + 1;
    parameter TXDAT_BE_MSB          = TXDAT_BE_LSB + BE_W - 1;

    parameter TXDAT_DATCNT_LSB      = TXDAT_BE_MSB + TRACETAG_W + 1;
    parameter TXDAT_DATCNT_MSB      = TXDAT_DATCNT_LSB + DATCNT_W - 1;

    // RXDAT Field  
    parameter RXDAT_TXNID_LSB       = 4;
    parameter RXDAT_TXNID_MSB       = RXDAT_TXNID_LSB + TXNID_W - 1;

    parameter RXDAT_OPCODE_LSB      = RXDAT_TXNID_MSB + 1;
    parameter RXDAT_OPCODE_MSB      = RXDAT_OPCODE_LSB + DATOPCODE_W - 1;

    parameter RXDAT_DATAID_LSB      = RXDAT_OPCODE_MSB + DATRESPERR_W + 1;
    parameter RXDAT_DATAID_MSB      = RXDAT_DATAID_LSB + DATAID_W - 1;

    parameter RXDAT_DATA_LSB        = RXDAT_DATAID_MSB + 1;
    parameter RXDAT_DATA_MSB        = RXDAT_DATA_LSB + DATA_W - 1;

    typedef struct packed {
        logic [NID_W-1:0]                   req_srcid;
        logic [NID_W-1:0]                   req_tgtid;
        logic [REQADDR_W-1:0]               req_addr;
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
            req_info.req_srcid      = '0;
            req_info.req_tgtid      = req_flit[REQ_TGTID_MSB    : REQ_TGTID_LSB ];
            req_info.req_addr       = req_flit[REQ_ADDR_MSB     : REQ_ADDR_LSB  ];
            req_info.req_txnid      = req_flit[REQ_TXNID_MSB    : REQ_TXNID_LSB ];
            req_info.req_order      = req_flit[REQ_ORDER_MSB    : REQ_ORDER_LSB ];
            req_info.req_allowretry = req_flit[REQ_ALLOWRETRY_LSB               ];
            req_info.req_opcode     = req_flit[REQ_OPCODE_MSB   : REQ_OPCODE_LSB];
            req_info.req_size       = req_flit[REQ_SIZE_MSB     : REQ_SIZE_LSB  ];
            req_info.req_be         = req_flit[REQ_BE_MSB       : REQ_BE_LSB    ];
            req_info.req_secvec     = req_flit[REQ_SECVEC_MSB   : REQ_SECVEC_LSB];
            req_info.req_be         = '0;
            req_info.req_dbid       = '0;
        return req_info;
    endfunction

    function rsp_info_t rsp_flit2struct(logic [MST_RSP_W-1:0] rsp_flit);
        rsp_info_t rsp_info;
            rsp_info.rsp_srcid      = '0;
            rsp_info.rsp_tgtid      = rsp_flit[RSP_TGTID_MSB    : RSP_TGTID_LSB     ];
            rsp_info.rsp_txnid      = rsp_flit[RSP_TXNID_MSB    : RSP_TXNID_LSB     ];
            rsp_info.rsp_dbid       = rsp_flit[RSP_DBID_MSB     : RSP_DBID_LSB      ];
            rsp_info.rsp_pcrdtype   = rsp_flit[RSP_PCRDTYPE_MSB : RSP_PCRDTYPE_LSB  ];
            rsp_info.rsp_opcode     = rsp_flit[RSP_OPCODE_MSB   : RSP_OPCODE_LSB    ];
        return rsp_info;
    endfunction

    function wdata_info_t wdat_flit2struct(logic [MST_DAT_W-1:0] dat_flit);
        wdata_info_t wdata_info;
            wdata_info.wdat_srcid   = '0;
            wdata_info.wdat_tgtid   = dat_flit[TXDAT_TGTID_MSB    : TXDAT_TGTID_LSB  ];
            wdata_info.wdat_txnid   = dat_flit[TXDAT_TXNID_MSB    : TXDAT_TXNID_LSB  ];
            wdata_info.wdat_data    = dat_flit[TXDAT_DATA_MSB     : TXDAT_DATA_LSB   ];
            wdata_info.wdat_be      = dat_flit[TXDAT_BE_MSB       : TXDAT_BE_LSB     ];
            wdata_info.wdat_dataid  = dat_flit[TXDAT_DATAID_MSB   : TXDAT_DATAID_LSB ];
            wdata_info.wdat_datacnt = dat_flit[TXDAT_DATCNT_MSB   : TXDAT_DATCNT_LSB ];
        return wdata_info;
    endfunction

    function rdata_info_t rdat_flit2struct(logic [MST_DAT_W-1:0] dat_flit);
        rdata_info_t rdata_info;
            rdata_info.rdat_srcid   = '0;
            rdata_info.rdat_tgtid   = '0;
            rdata_info.rdat_txnid   = dat_flit[RXDAT_TXNID_MSB    : RXDAT_TXNID_LSB  ];
            rdata_info.rdat_data    = dat_flit[RXDAT_DATA_MSB     : RXDAT_DATA_LSB   ];
            rdata_info.rdat_dataid  = dat_flit[RXDAT_DATAID_MSB   : RXDAT_DATAID_LSB ];
            rdata_info.rdat_dbid    = '0;
            rdata_info.rdat_opcode  = dat_flit[RXDAT_OPCODE_MSB   : RXDAT_OPCODE_LSB ];
        return rdata_info;
    endfunction


 endpackage