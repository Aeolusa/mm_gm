//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================


module mm_rddbuf
import mm_pkg::*;
#(
    parameter mst_idx = 0

) (
    input   bit                                                             clk,
    input   bit                                                             rstn,
    // wdata from DUT
    input   logic [MST_DATCHN_NUMS-1:0]                                     valid_CompData,
    input   rdata_info_t [MST_DATCHN_NUMS-1:0]                              rdata_info,

    input   logic                                                           rddbuf_valid,
    input   rdreq_t                                                         rddbuf_req,
    // To glb sram
    output  req_upld_t                                                      glbsram_rdreq,
    output  logic                                                           glbsram_rdvalid,
    input   dat_upld_t                                                      glbsram_data,
    input   logic                                                           glbsram_data_valid, 
    // ras
    output  logic                                                           err

);

    // assert 
    // 1. reqentry full but still alloc


    localparam RDBUF_PTR_W = $clog2(RD_OST);

    rdreq_list_t [RD_OST-1:0]           rdreq_entry;
    logic [RD_OST-1:0]                  rdreq_entry_valid;
    logic [RDBUF_PTR_W-1:0]             reqentry_alloc_ptr;
    // represent dut data arrived, level signal
    logic [RD_OST-1:0]                  dut_data_en;
    // represent sram data arrived, level signal
    logic [RD_OST-1:0]                  sram_data_en;
    logic [RD_OST-1:0]                  reqentry_dealloc;
    logic                               dealloc_update;
    logic [RD_OST-1:0][RDDATA_W-1:0]    dut_datbuf;
    logic [RD_OST-1:0][RDDATA_W-1:0]    glbsram_datbuf;
    logic [RDBUF_PTR_W-1:0]             dutdat_cam_ptr;
    logic [RDBUF_PTR_W-1:0]             last_alloc_ptr;
    logic                               entry_empty_alloc;
    logic [RD_OST-1:0]                  nxt_ptr_valid;
    logic [RD_OST-1:0]                  head_vec;
    logic [RDBUF_PTR_W-1:0]             head_ones;

    bit                                 err_headnoOnehot;

    assign err                  = err_headnoOnehot;

    assign err_headnoOnehot     = (head_ones > 1) || entry_empty_alloc; 
    assign entry_empty_alloc    = (&rdreq_entry_valid == 0) && rddbuf_valid;
 
    assign dealloc_update       = |reqentry_dealloc;

    always_comb begin
        head_ones = 0;
        for (int i = 0; i < RD_OST; i++) begin
            head_ones = head_ones + head_vec[i];
        end
    end

    always_comb begin
        reqentry_alloc_ptr = 0;
        for (int i = 0; i < RD_OST; i++) begin: u_reqentry_empty
            if (rdreq_entry_valid[i] == 0) begin
                reqentry_alloc_ptr = i;
                disable u_reqentry_empty;
            end
        end
    end

    always_comb begin
        dutdat_cam_ptr = 0;
        for (int i = 0; i < RD_OST; i++) begin: u_dutdat_cam
            if (valid_CompData && 
                (rdata_info.rdat_srcid == rdreq_entry[i].rdreq.rdreq_tgtid) &&
                (rdata_info.rdat_txnid == rdreq_entry[i].rdreq.rdreq_txnid)) begin
                dutdat_cam_ptr = i;
                disable u_dutdat_cam;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rstn) begin
            last_alloc_ptr <= 'd0;
        end else if (rddbuf_valid) begin
            last_alloc_ptr <= reqentry_alloc_ptr;
        end
    end

    generate

        for (genvar idx = 0; idx < RD_OST; idx++) begin

            assign reqentry_dealloc[idx]                        = dut_data_en[idx] & sram_data_en[idx];      
            assign head_vec[idx]                                = rdreq_entry[idx].head;   
            assign sram_data_en[idx]                            = glbsram_data_valid && head_vec[idx];  

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    sram_data_en[idx]                           <= 1'b0;
                end else if (glbsram_data_valid && head_vec[idx]) begin
                    sram_data_en[idx]                           <= 1'b1;
                end else begin
                    sram_data_en[idx]                           <= 1'b0;
                end
            end         

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    dut_data_en[idx]                            <= 1'b0;
                end else begin 
                    case (rdreq_entry[idx].rdreq.req_size)
                        'h0: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd1) ? 1'b1 : 1'b0;
                        'h1: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd1) ? 1'b1 : 1'b0;
                        'h2: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd1) ? 1'b1 : 1'b0;
                        'h3: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd1) ? 1'b1 : 1'b0;
                        'h4: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd1) ? 1'b1 : 1'b0;
                        'h5: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd1) ? 1'b1 : 1'b0;
                        'h6: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd2) ? 1'b1 : 1'b0;
                        'h7: dut_data_en[idx]                   <= (rdreq_entry[idx].dut_dat_nums == 'd4) ? 1'b1 : 1'b0;
                        default: dut_data_en[idx]               <= 1'b0;
                    endcase 
                end
            end 

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    rdreq_entry_valid[idx]                      <= 1'b0;
                end else if (reqentry_dealloc[idx]) begin
                    rdreq_entry_valid[idx]                      <= 1'b0;
                end else if (rddbuf_valid && (reqentry_alloc_ptr == idx)) begin
                    rdreq_entry_valid[idx]                      <= 1'b1;
                end
            end
            
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    rdreq_entry[idx].rdreq.rdreq_srcid          <= 'd0; 
                    rdreq_entry[idx].rdreq.rdreq_tgtid          <= 'd0;
                    rdreq_entry[idx].rdreq.rdreq_txnid          <= 'd0;
                    rdreq_entry[idx].rdreq.rdreq_addr           <= 'd0;
                    rdreq_entry[idx].rdreq.rdreq_size           <= 'd0;
                    rdreq_entry[idx].rdreq.rdreq_order          <= 'd0;
                end else if (rddbuf_valid && (reqentry_alloc_ptr == idx)) begin
                    rdreq_entry[idx].rdreq.rdreq_srcid          <= rddbuf_req.rdreq_srcid; 
                    rdreq_entry[idx].rdreq.rdreq_tgtid          <= rddbuf_req.rdreq_tgtid;
                    rdreq_entry[idx].rdreq.rdreq_txnid          <= rddbuf_req.rdreq_txnid;
                    rdreq_entry[idx].rdreq.rdreq_addr           <= rddbuf_req.rdreq_addr;
                    rdreq_entry[idx].rdreq.rdreq_size           <= rddbuf_req.rdreq_size;
                    rdreq_entry[idx].rdreq.rdreq_order          <= rddbuf_req.rdreq_order;
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    rdreq_entry[idx].dut_dat_nums               <= 'd0;
                end else if (valid_CompData && reqentry_dealloc[idx]) begin
                    rdreq_entry[idx].dut_dat_nums               <= 'd0;
                end else if (valid_CompData && (dutdat_cam_ptr == idx)) begin
                    rdreq_entry[idx].dut_dat_nums               <= rdreq_entry[idx].dut_dat_nums + 'd1;
                end
            end

            // list to order the return data of sram
            // Cause data from dut can do cam to find entry
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    rdreq_entry[idx].nxt_ptr                    <= 'd0;
                end else if (rddbuf_valid && (idx == last_alloc_ptr)) begin
                    rdreq_entry[idx].nxt_ptr                    <= reqentry_alloc_ptr;
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    nxt_ptr_valid[idx]                          <= 1'b0;
                end else if (reqentry_dealloc[idx]) begin
                    nxt_ptr_valid[idx]                          <= 1'b0;
                end else if (~entry_empty_alloc && (idx == last_alloc_ptr)) begin
                    nxt_ptr_valid[idx]                          <= 1'b1;
                end
            end

            // should consider when alloc and dealloc in same cycle
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    rdreq_entry[idx].head                       <= 1'b0;
                end else if ((entry_empty_alloc && (idx == reqentry_alloc_ptr)) || 
                             (dealloc_update && (idx == rdreq_entry[head_ptr].nxt_ptr))) begin 
                    rdreq_entry[idx].head                       <= 1'b1;
                end else if (dealloc_update && reqentry_dealloc[idx]) begin
                    rdreq_entry[idx].head                       <= 1'b0;
                end
            end

            always_ff @(posedge clk) begin
                if (!rstn) begin
                    dut_datbuf[idx]                             <= 'd0;
                end else if (reqentry_dealloc[idx]) begin
                    dut_datbuf[idx]                             <= 'd0;
                end else if (valid_CompData && (dutdat_cam_ptr == idx)) begin
                    case (rdata_info.rdat_dataid)
                        `FLIT0_ENC: dut_datbuf[idx][`FLIT0]     <= rdata_info.rdat_data;
                        `FLIT1_ENC: dut_datbuf[idx][`FLIT1]     <= rdata_info.rdat_data;
                        `FLIT2_ENC: dut_datbuf[idx][`FLIT2]     <= rdata_info.rdat_data;
                        `FLIT3_ENC: dut_datbuf[idx][`FLIT3]     <= rdata_info.rdat_data;
                    endcase
                end
            end
            
            always_ff @(posedge clk) begin
                if (!rstn) begin
                    glbsram_datbuf[idx]                         <= 'd0;
                end else if (reqentry_dealloc[idx]) begin
                    glbsram_datbuf[idx]                         <= 'd0;
                end else if (glbsram_data_valid && head_vec[idx]) begin
                    glbsram_datbuf[idx]                         <= glbsram_data;
                end
            end

        end
    endgenerate

    always_ff @(posedge clk) begin
        if (!rstn) begin 
            glbsram_rdreq.req_addr                              <= 'd0;
            glbsram_rdreq.req_rw                                <= 'd0;
            glbsram_rdreq.req_wrdata                            <= 'd0;
            glbsram_rdreq.req_be                                <= 'd0;
            glbsram_rdreq.req_sec_id                            <= 'd0;
        end else if (rddbuf_valid) begin
            glbsram_rdreq.req_addr                              <= rddbuf_req.wrreq_addr;
            glbsram_rdreq.req_rw                                <= 1'b0;
            glbsram_rdreq.req_wrdata                            <= 'd0;
            glbsram_rdreq.req_be                                <= 'd0;
            glbsram_rdreq.req_sec_id                            <= mst_idx;
        end
    end

    always_ff @(posedge clk) begin
        if (!rstn) begin
            glbsram_rdvalid                                     <= 1'b0;
        end else begin
            glbsram_rdvalid                                     <= rddbuf_valid;
        end
    end
    


endmodule
