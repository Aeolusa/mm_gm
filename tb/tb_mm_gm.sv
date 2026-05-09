`timescale 1ns/1ps
`include "mm_defines.sv"

module tb_mm_gm;
    import mm_pkg::*;

    logic clk;
    logic rstn;

    // Clock and Reset
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rstn = 0;
        #20 rstn = 1;
    end

    // =========================================================================
    // DUT Signals
    // =========================================================================

    // SM
    logic [SM_NUMS-1:0][SM_REQCHN_NUMS-1:0][SM_REQ_W-1:0]           sm_txreq_flit;
    logic [SM_NUMS-1:0][SM_REQCHN_NUMS-1:0]                         sm_txreq_flitv;
    logic [SM_NUMS-1:0][SM_TXRSPCHN_NUMS-1:0][SM_RSP_W-1:0]         sm_txrsp_flit;
    logic [SM_NUMS-1:0][SM_TXRSPCHN_NUMS-1:0]                       sm_txrsp_flitv;
    logic [SM_NUMS-1:0][SM_RXRSPCHN_NUMS-1:0][SM_RSP_W-1:0]         sm_rxrsp_flit;
    logic [SM_NUMS-1:0][SM_RXRSPCHN_NUMS-1:0]                       sm_rxrsp_flitv;
    logic [SM_NUMS-1:0][SM_TXDATCHN_NUMS-1:0][SM_TXDAT_W-1:0]       sm_txdat_flit;
    logic [SM_NUMS-1:0][SM_TXDATCHN_NUMS-1:0]                       sm_txdat_flitv;
    logic [SM_NUMS-1:0][SM_RXDATCHN_NUMS-1:0][SM_RXDAT_W-1:0]       sm_rxdat_flit;
    logic [SM_NUMS-1:0][SM_RXDATCHN_NUMS-1:0]                       sm_rxdat_flitv;

    // HOST
    logic [HST_REQCHN_NUMS-1:0][HST_REQ_W-1:0]                      host_txreq_flit;
    logic [HST_REQCHN_NUMS-1:0]                                     host_txreq_flitv;
    logic [HST_TXRSPCHN_NUMS-1:0][HST_RSP_W-1:0]                    host_txrsp_flit;
    logic [HST_TXRSPCHN_NUMS-1:0]                                   host_txrsp_flitv;
    logic [HST_RXRSPCHN_NUMS-1:0][HST_RSP_W-1:0]                    host_rxrsp_flit;
    logic [HST_RXRSPCHN_NUMS-1:0]                                   host_rxrsp_flitv;
    logic [HST_TXDATCHN_NUMS-1:0][HST_TXDAT_W-1:0]                  host_txdat_flit;
    logic [HST_TXDATCHN_NUMS-1:0]                                   host_txdat_flitv;
    logic [HST_RXDATCHN_NUMS-1:0][HST_RXDAT_W-1:0]                  host_rxdat_flit;
    logic [HST_RXDATCHN_NUMS-1:0]                                   host_rxdat_flitv;

    // TS
    logic [TS_REQCHN_NUMS-1:0][TS_REQ_W-1:0]                        ts_txreq_flit;
    logic [TS_REQCHN_NUMS-1:0]                                      ts_txreq_flitv;
    logic [TS_TXRSPCHN_NUMS-1:0][TS_RSP_W-1:0]                      ts_txrsp_flit;
    logic [TS_TXRSPCHN_NUMS-1:0]                                    ts_txrsp_flitv;
    logic [TS_RXRSPCHN_NUMS-1:0][TS_RSP_W-1:0]                      ts_rxrsp_flit;
    logic [TS_RXRSPCHN_NUMS-1:0]                                    ts_rxrsp_flitv;
    logic [TS_TXDATCHN_NUMS-1:0][TS_TXDAT_W-1:0]                    ts_txdat_flit;
    logic [TS_TXDATCHN_NUMS-1:0]                                    ts_txdat_flitv;
    logic [TS_RXDATCHN_NUMS-1:0][TS_RXDAT_W-1:0]                    ts_rxdat_flit;
    logic [TS_RXDATCHN_NUMS-1:0]                                    ts_rxdat_flitv;

    // BLIT
    logic [BLIT_REQCHN_NUMS-1:0][BLIT_REQ_W-1:0]                    blit_txreq_flit;
    logic [BLIT_REQCHN_NUMS-1:0]                                    blit_txreq_flitv;
    logic [BLIT_TXRSPCHN_NUMS-1:0][BLIT_RSP_W-1:0]                  blit_txrsp_flit;
    logic [BLIT_TXRSPCHN_NUMS-1:0]                                  blit_txrsp_flitv;
    logic [BLIT_RXRSPCHN_NUMS-1:0][BLIT_RSP_W-1:0]                  blit_rxrsp_flit;
    logic [BLIT_RXRSPCHN_NUMS-1:0]                                  blit_rxrsp_flitv;
    logic [BLIT_TXDATCHN_NUMS-1:0][BLIT_TXDAT_W-1:0]                blit_txdat_flit;
    logic [BLIT_TXDATCHN_NUMS-1:0]                                  blit_txdat_flitv;
    logic [BLIT_RXDATCHN_NUMS-1:0][BLIT_RXDAT_W-1:0]                blit_rxdat_flit;
    logic [BLIT_RXDATCHN_NUMS-1:0]                                  blit_rxdat_flitv;

    // Initialization
    initial begin
        sm_txreq_flit = '0; sm_txreq_flitv = '0;
        sm_txrsp_flit = '0; sm_txrsp_flitv = '0;
        sm_rxrsp_flit = '0; sm_rxrsp_flitv = '0;
        sm_txdat_flit = '0; sm_txdat_flitv = '0;
        sm_rxdat_flit = '0; sm_rxdat_flitv = '0;

        host_txreq_flit = '0; host_txreq_flitv = '0;
        host_txrsp_flit = '0; host_txrsp_flitv = '0;
        host_rxrsp_flit = '0; host_rxrsp_flitv = '0;
        host_txdat_flit = '0; host_txdat_flitv = '0;
        host_rxdat_flit = '0; host_rxdat_flitv = '0;

        ts_txreq_flit = '0; ts_txreq_flitv = '0;
        ts_txrsp_flit = '0; ts_txrsp_flitv = '0;
        ts_rxrsp_flit = '0; ts_rxrsp_flitv = '0;
        ts_txdat_flit = '0; ts_txdat_flitv = '0;
        ts_rxdat_flit = '0; ts_rxdat_flitv = '0;

        blit_txreq_flit = '0; blit_txreq_flitv = '0;
        blit_txrsp_flit = '0; blit_txrsp_flitv = '0;
        blit_rxrsp_flit = '0; blit_rxrsp_flitv = '0;
        blit_txdat_flit = '0; blit_txdat_flitv = '0;
        blit_rxdat_flit = '0; blit_rxdat_flitv = '0;
    end

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    mm_gm u_mm_gm (.*);

    // =========================================================================
    // Monitor Internal Errors
    // =========================================================================
    logic any_err;
    // Bind to internal err signals
    assign any_err = u_mm_gm.sm_alloc[0].u_sm_allocator.err | u_mm_gm.u_host_allocator.err;

    always @(posedge clk) begin
        if (rstn && any_err) begin
            $display("[ERROR] mm_gm checker detected a memory consistency error at time %0t", $time);
            #100;
            $finish;
        end
    end

    // =========================================================================
    // Helper Tasks to Drive Traffic
    // =========================================================================
    
    task automatic sm_write_nosnp_full(input logic [REQADDR_W-1:0] addr, input logic [DATA_W-1:0] data, input logic [TXNID_W-1:0] txnid, input logic [DBID_W-1:0] dbid);
        req_info_t req;
        wdata_info_t wdat;
        rsp_info_t rxrsp;

        // 1. Send WriteNoSnpFull Request
        @(posedge clk);
        req = '0;
        req.req_opcode = `OP_WRITENOSNPFULL;
        req.req_addr = addr;
        req.req_txnid = txnid;
        req.req_size = 3'b110; // 64B
        req.req_be = '1; // Full BE

        // Cast struct to flit bits (manual or via system casting)
        sm_txreq_flit[0][0][REQ_OPCODE_MSB:REQ_OPCODE_LSB] <= req.req_opcode;
        sm_txreq_flit[0][0][REQ_ADDR_MSB:REQ_ADDR_LSB] <= req.req_addr;
        sm_txreq_flit[0][0][REQ_TXNID_MSB:REQ_TXNID_LSB] <= req.req_txnid;
        sm_txreq_flit[0][0][REQ_SIZE_MSB:REQ_SIZE_LSB] <= req.req_size;
        sm_txreq_flitv[0][0] <= 1'b1;

        @(posedge clk);
        sm_txreq_flitv[0][0] <= 1'b0;

        // 2. Mock Interconnect DBIDResp (assuming checker might look for this)
        // Wait a few cycles
        repeat(5) @(posedge clk);
        rxrsp = '0;
        rxrsp.rsp_opcode = `OP_COMPDBIDRESP; // CompDBIDResp
        rxrsp.rsp_txnid = txnid;
        rxrsp.rsp_dbid = dbid;
        
        sm_rxrsp_flit[0][0][RSP_OPCODE_MSB:RSP_OPCODE_LSB] <= rxrsp.rsp_opcode;
        sm_rxrsp_flit[0][0][RSP_TXNID_MSB:RSP_TXNID_LSB] <= rxrsp.rsp_txnid;
        sm_rxrsp_flit[0][0][RSP_DBID_MSB:RSP_DBID_LSB] <= rxrsp.rsp_dbid;
        sm_rxrsp_flitv[0][0] <= 1'b1; // valid_CompDBIDResp expects sm_rxrsp_flitv

        @(posedge clk);
        sm_rxrsp_flitv[0][0] <= 1'b0;

        // 3. Send Write Data (NCBWrData)
        repeat(2) @(posedge clk);
        wdat = '0;
        wdat.wdat_txnid = dbid; // write data typically uses DBID as TXNID
        wdat.wdat_data = {4{data}}; // Extend to DATALINE_W or just fill
        
        sm_txdat_flit[0][0][TXDAT_TXNID_MSB:TXDAT_TXNID_LSB] <= wdat.wdat_txnid;
        sm_txdat_flit[0][0][TXDAT_DATA_MSB:TXDAT_DATA_LSB] <= data;
        sm_txdat_flit[0][0][TXDAT_OPCODE_MSB:TXDAT_OPCODE_LSB] <= `OP_NCBWRDATA;
        sm_txdat_flitv[0][0] <= 1'b1;

        @(posedge clk);
        sm_txdat_flitv[0][0] <= 1'b0;
    endtask

    task automatic host_read_nosnp(input logic [REQADDR_W-1:0] addr, input logic [DATA_W-1:0] mock_rdata, input logic [TXNID_W-1:0] txnid);
        req_info_t req;
        rdata_info_t rdat;

        // 1. Send ReadNoSnp Request from HOST
        @(posedge clk);
        req = '0;
        req.req_opcode = `OP_READNOSNP;
        req.req_addr = addr;
        req.req_txnid = txnid;
        
        host_txreq_flit[0][REQ_OPCODE_MSB:REQ_OPCODE_LSB] <= req.req_opcode;
        host_txreq_flit[0][REQ_ADDR_MSB:REQ_ADDR_LSB] <= req.req_addr;
        host_txreq_flit[0][REQ_TXNID_MSB:REQ_TXNID_LSB] <= req.req_txnid;
        host_txreq_flitv[0] <= 1'b1;

        @(posedge clk);
        host_txreq_flitv[0] <= 1'b0;

        // 2. Mock Interconnect CompData Response
        repeat(10) @(posedge clk);
        rdat = '0;
        rdat.rdat_opcode = `OP_COMPDATA;
        rdat.rdat_txnid = txnid;
        rdat.rdat_data = mock_rdata;
        
        host_rxdat_flit[0][RXDAT_OPCODE_MSB:RXDAT_OPCODE_LSB] <= rdat.rdat_opcode;
        host_rxdat_flit[0][RXDAT_TXNID_MSB:RXDAT_TXNID_LSB] <= rdat.rdat_txnid;
        host_rxdat_flit[0][RXDAT_DATA_MSB:RXDAT_DATA_LSB] <= rdat.rdat_data;
        host_rxdat_flitv[0] <= 1'b1;

        @(posedge clk);
        host_rxdat_flitv[0] <= 1'b0;
    endtask

    // =========================================================================
    // Test Sequence
    // =========================================================================
    initial begin
        // Wait for reset
        wait(rstn == 1'b1);
        repeat(10) @(posedge clk);

        $display("---------------------------------------------------------");
        $display("[INFO] Starting MM_GM Test Sequence");
        $display("---------------------------------------------------------");

        // Test 1: Write correct data from SM0 and Read from HOST
        $display("[INFO] Test 1: Write and Read Matching Data");
        sm_write_nosnp_full(54'h1000, 256'hDEADBEEF, 12'h001, 12'h101);
        repeat(20) @(posedge clk);
        
        // Host reads the same address, interconnect mocks correct data
        host_read_nosnp(54'h1000, 256'hDEADBEEF, 12'h002);
        repeat(20) @(posedge clk);
        
        if (!any_err)
            $display("[PASS] Test 1 completed without errors.");
        else
            $display("[FAIL] Test 1 failed.");

        // Test 2: Error Injection. SM0 writes, HOST reads wrong data from Interconnect
        $display("[INFO] Test 2: Error Injection (Checker should assert error)");
        sm_write_nosnp_full(54'h2000, 256'h11112222, 12'h003, 12'h103);
        repeat(20) @(posedge clk);

        // Host reads the same address, interconnect returns WRONG data
        // Expecting mm_gm to catch this and assert err
        host_read_nosnp(54'h2000, 256'h99999999, 12'h004);
        repeat(20) @(posedge clk);

        if (any_err) begin
            $display("[PASS] Test 2: Checker successfully caught the consistency error.");
        end else begin
            $display("[FAIL] Test 2: Checker missed the error.");
        end

        #100;
        $display("---------------------------------------------------------");
        $display("[INFO] Simulation Finished");
        $display("---------------------------------------------------------");
        $finish;
    end

    // =========================================================================
    // Waveform Dumping
    // =========================================================================
    initial begin
        // Dump VCD
        $dumpfile("tb_mm_gm.vcd");
        $dumpvars(0, tb_mm_gm);
        
        // Uncomment if you use FSDB
        // $fsdbDumpfile("tb_mm_gm.fsdb");
        // $fsdbDumpvars(0, tb_mm_gm);
    end

endmodule
