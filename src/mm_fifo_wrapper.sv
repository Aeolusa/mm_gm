//=============================================================================
// Author:      libo
// Email:       libo2353@phytium.com.cn
// Date:        2026-04-14
// Description: FIFO and SRAM logic
//=============================================================================
module mm_fifo_wrapper
import mm_pkg::*;
#(
    parameter MST_NUM = 1,
    parameter SRAM_ADDR_WIDTH = 32,
    parameter SRAM_DATA_WIDTH = 1024
) (
    input   bit                                                             clk,    
    input   bit                                                             rstn,   
    //interface with mm_compTo_fifo
    input   req_upld_t                                                      fifo_rdreq,
    input   logic                                                           fifo_rdvalid,
    input   req_upld_t                                                      fifo_wrreq,
    input   logic                                                           fifo_wrvalid,
    //interface to SRAM
    output  [SRAM_ADDR_WIDTH - 1 : 0]                                       wr_addr,
    output  [SRAM_DATA_WIDTH - 1 : 0]                                       wr_data,
    output  logic                                                           wr_en,
    output  [BE_W - 1 : 0]                                                  wr_be,
    output  [SRAM_ADDR_WIDTH - 1 : 0]                                       rd_addr,
    input   logic                                                           sram_wr_ready,
    input   logic                                                           sram_rd_ready,
    output  logic                                                           rd_en
);

    bit wr_valid;
    bit [SRAM_ADDR_WIDTH - 1 : 0] wr_fifo_addr;
    bit [SRAM_DATA_WIDTH - 1 : 0] wr_fifo_data;
    bit [BE_W - 1 : 0] wr_fifo_be;
    bit rd_valid;
    bit [SRAM_ADDR_WIDTH - 1 : 0] rd_fifo_addr;
    bit [SRAM_DATA_WIDTH - 1 : 0] rd_fifo_data;
    req_upld_t fifo_wrreq_reg;
    bit wrfifo_full;
    bit wrfifo_empty;
    bit wrdata_vld;
    req_upld_t fifo_rdreq_reg;
    bit rdfifo_empty;
    bit rdfifo_full;

    mm_fifo #(
        .DATA_WIDTH($bits(req_upld_t)),
        .DEPTH(MST_NUM * MST_NUM)
    ) wr_req_fifo (
        .clk(clk),
        .rst_n(rstn),
        .wr_en(fifo_wrvalid),
        .rd_en(sram_wr_ready && !wrfifo_empty),
        .din(fifo_wrreq),
        .dout(fifo_wrreq_reg),
        .full(wrfifo_full),
        .empty(wrfifo_empty),
        .data_count()
    );

    mm_fifo #(
        .DATA_WIDTH(SRAM_DATA_WIDTH),
        .DEPTH(MST_NUM * MST_NUM)
    ) rd_data_fifo (
        .clk(clk),
        .rst_n(rstn),
        .wr_en(fifo_rdvalid),
        .rd_en(sram_rd_ready && !rdfifo_empty),
        .din(fifo_rdreq),
        .dout(fifo_rdreq_reg),
        .full(rdfifo_full),
        .empty(rdfifo_empty),
        .data_count()
    );



    always_ff @(posedge clk or negedge rstn) begin 
        if(!rstn) begin
            wr_valid <= '0;
            wr_fifo_addr <= '0;
            wr_fifo_data <= '0;
            wrdata_vld <= 1'b0;
        end
        else begin
            if(sram_wr_ready && !wrfifo_empty) begin
                wr_fifo_addr <= fifo_wrreq_reg.req_addr;
                wr_fifo_data <= fifo_wrreq_reg.req_wrdata;
                wr_fifo_be <= fifo_wrreq_reg.req_be;
                wr_valid <= 1'b1;
            end
            else begin
                wr_valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rd_valid <= '0;
            rd_fifo_addr <= '0;
            rd_fifo_data <= '0;
        end else begin
            if(sram_rd_ready && !rdfifo_empty) begin
                rd_fifo_addr <= fifo_rdreq_reg.req_addr;
                rd_valid <= 1'b1;
            end
            else begin
                rd_valid <= 1'b0;
            end
        end
    end

    assign wr_en = wr_valid;
    assign wr_addr = wr_fifo_addr;
    assign wr_data = wr_fifo_data;
    assign wr_be = wr_fifo_be;
    assign rd_en = rd_valid;
    assign rd_addr = rd_fifo_addr;


endmodule