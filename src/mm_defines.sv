    // DATAID encode
    `define FLIT0_ENC               4'b0000;
    `define FLIT1_ENC               4'b0010;
    `define FLIT2_ENC               4'b0100;
    `define FLIT3_ENC               4'b0110;

    `define FLIT0                   255:0;
    `define FLIT1                   511:256;
    `define FLIT2                   767:512;
    `define FLIT3                   1023:768;

     // TBD 
    `define REQ_OP                  30:27
    `define OP_READNOSNP            'h1
    `define OP_WRITENOSNPPTL        'h3
    `define OP_WRITENOSNPFULL       'h2

    `define RSP_OP                  29:27
    `define OP_RETRYACK             'h1
    `define OP_COMP                 'h4
    `define OP_COMPDBIDRESP         'h5
    `define OP_DBIDRESP             'h3
    `define OP_READRECEIPT          'h6
    
    `define DAT_OP                  28:27
    `define OP_COMPDATA             'h2
    `define OP_NCBWRDATA            'h1