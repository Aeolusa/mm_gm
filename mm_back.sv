module mm_back
import mm_pkg::*;
#(
    parameter MST_NUM = 1,
    parameter SRAM_ADDR_WIDTH = 32,
    parameter SRAM_DATA_WIDTH = 1024
) (
    input   bit                                                             clk,
    input   bit                                                             rstn,
    input   req_upld_t                                                      rdreq_flit,
    input   logic                                                           rdreq_flitv,
    input   req_upld_t                                                      wrreq_flit,
    input   logic                                                           wrreq_flitv,
    output  req_upld_t                                                      rd_data_flit,
    output  logic                                                           rd_data_flitv
);

    wire u_fifo_rdvalid;
    wire u_fifo_wrvalid;
    req_upld_t u_fifo_rdreq;
    req_upld_t u_fifo_wrreq;
    logic [SRAM_ADDR_WIDTH - 1 : 0] u_sram_wr_addr;
    logic [SRAM_DATA_WIDTH - 1 : 0] u_sram_wr_data;
    logic u_sram_wr_en;
    logic [BE_W - 1 : 0] u_sram_wr_be;
    logic [SRAM_ADDR_WIDTH - 1 : 0] u_sram_rd_addr;
    logic u_sram_rd_en;
    logic u_sram_wr_ready;
    logic u_sram_rd_ready;
    logic u_sram_rd_valid;
    logic [SRAM_DATA_WIDTH - 1 : 0] u_sram_rd_data
    req_data_flit_t rd_data_flit_buf;
    logic rd_data_flitv_buf;

    assign rd_data_flit = rd_data_flit_buf;
    assign rd_data_flitv = rd_data_flitv_buf;

    mm_compTo_fifo #(
        .MST_NUM(MST_NUM)
    ) compTo_fifo (
        .clk(clk),
        .rstn(rstn),
        .glbsram_rdreq(rdreq_flit),
        .glbsram_rdvalid(rdreq_flitv),
        .glbsram_data(rd_data_flit_buf),
        .glbsram_data_valid(rd_data_flitv_buf),
        .glbsram_wrreq(wrreq_flit),
        .glbsram_wrvalid(wrreq_flitv),
        .fifo_rdreq(u_fifo_rdreq),
        .fifo_rdvalid(u_fifo_rdvalid),
        .fifo_data(u_sram_rd_data),
        .fifo_data_valid(u_sram_rd_valid),
        .fifo_wrreq(u_fifo_wrreq),
        .fifo_wrvalid(u_fifo_wrvalid)
    );

    mm_fifo_wrapper #(
        .MST_NUM(MST_NUM),
        .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
        .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH)
    ) fifo_wrapper (
        .clk(clk),
        .rstn(rstn),
        .fifo_rdreq(u_fifo_rdreq),
        .fifo_rdvalid(u_fifo_rdvalid),
        .fifo_wrreq(u_fifo_wrreq),
        .fifo_wrvalid(u_fifo_wrvalid),
        .wr_addr(u_sram_wr_addr),
        .wr_data(u_sram_wr_data),
        .wr_en(u_sram_wr_en),
        .wr_be(u_sram_wr_be),
        .rd_addr(u_sram_rd_addr),
        .sram_wr_ready(u_sram_wr_ready),
        .sram_rd_ready(u_sram_rd_ready),
        .rd_en(u_sram_rd_en)
    );  

    mm_sram #(
        .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
        .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH)
    ) sram (
        .clk(clk),
        .rstn(rstn),
        .wr_addr(u_sram_wr_addr),
        .wr_data(u_sram_wr_data),
        .wr_en(u_sram_wr_en),
        .wr_be(u_sram_wr_be),
        .rd_addr(u_sram_rd_addr),
        .rd_en(u_sram_rd_en),
        .wr_ready(u_sram_wr_ready),
        .rd_ready(u_sram_rd_ready),
        .rd_valid(u_sram_rd_valid),
        .rd_data(u_sram_rd_data)
    );

endmodule