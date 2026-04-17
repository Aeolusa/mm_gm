module mm_sram
import mm_pkg::*;
(
    input  bit                                                             clk,
    input  bit                                                             rstn,
    //interface with mm_fifo_wrapper
    input  [SRAM_ADDR_WIDTH - 1 : 0]                                       wr_addr,
    input  [SRAM_DATA_WIDTH - 1 : 0]                                       wr_data,
    input  logic                                                           wr_en,
    input  [BE_W - 1 : 0]                                                  wr_be,
    input  [SRAM_ADDR_WIDTH - 1 : 0]                                       rd_addr,
    input  logic                                                           rd_en,
    output logic                                                           wr_ready,
    output logic                                                           rd_ready,
    output logic                                                           rd_valid,
    output [SRAM_DATA_WIDTH - 1 : 0]                                       rd_data
);

//总的原则，写入，最多两拍，读只需一拍

    reg [1023 : 0] sram [4096];//2^(SRAM_ADDR_WIDTH - 7) because each address corresponds to 128B data
    logic wr_flag;
    logic rd_flag;
    reg [1023 : 0] rd_internal;
    reg [1023 : 0] wr_data_q;
    reg [1023 : 0] real_wrdata;

    //write logic

    always_comb begin 
        if(wr_flag) begin
            wr_ready = 1'b0;
        end else begin
            wr_ready = 1'b1;
        end
    end
//首先写，外部给到我的只有一拍的valid信号，所以需要先进行判断，看是否需要寄存，如果需要寄存，那么寄存之后，根据be信号来计算正确的写入数据
    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            
        end else begin
            if(wr_en) begin
                if(&(wr_be)) begin
                    sram[(wr_addr >> 7)] <= wr_data;//直接写入，不反压
                    wr_flag <= 1'b0;
                end else begin
                    rd_internal <= sram[(wr_addr >> 7)];
                    wr_data_q <= wr_data;
                    wr_flag <= 1'b1;
                end
            end
        end
    end

//如果寄存，那么计算正确的写数据
    always_comb begin
        if(wr_flag) begin
            real_wrdata = wr_data_q;
            for(int i = 0; i < BE_W; i++) begin
                if(!wr_be[i]) begin
                    real_wrdata[(i*8) +: 8] = rd_internal[(i*8) +: 8];
                end
            end
        end else begin
            real_wrdata = '0;
        end
    end

//两拍写入
    always_ff @(posedge clk or negedge rstn) begin 
        if(!rstn) begin
            
        end else begin
            if(wr_flag) begin
                sram[(wr_addr >> 7)] <= real_wrdata;
                wr_flag <= 1'b0;
            end
        end
    end

//读这里没有阻塞，rd_en同样有效一拍，下一拍读数据直接返回
    //read logic    
    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rd_valid <= 1'b0;
            rd_data <= '0;
            rd_ready <= 1'b0;
        end else begin
            if(rd_en) begin
                rd_data <= sram[(rd_addr >> 7)];
                rd_valid <= 1'b1;
                rd_ready <= 1'b1;
            end else begin
                rd_valid <= 1'b0;
                rd_ready <= 1'b1;
            end
        end
    end


endmodule