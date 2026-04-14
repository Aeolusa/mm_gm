//=============================================================================
// Author:      libo
// Email:       libo2353@phytium.com.cn
// Date:        2026-04-14
// Description: For collect req to FIFO
//=============================================================================
module mm_compTo_fifo
import mm_pkg::*;
#(
    parameter MST_NUM = 1
) (
    input   bit                                                             clk,
    input   bit                                                             rstn,

//interface with mm_allocator
    input   req_upld_t                                                      glbsram_rdreq[MST_NUM-1:0],
    input   logic                                                           glbsram_rdvalid[MST_NUM-1:0],
    output  dat_upld_t                                                      glbsram_data[MST_NUM-1:0],
    output  logic                                                           glbsram_data_valid[MST_NUM-1:0],
    input   req_upld_t                                                      glbsram_wrreq[MST_NUM-1:0],
    input   logic                                                           glbsram_wrvalid[MST_NUM-1:0],

//interface with FIFO
    output  req_upld_t                                                      fifo_rdreq,
    output  logic                                                           fifo_rdvalid,
    input   dat_upld_t                                                      fifo_data,//from sram
    input   logic                                                           fifo_data_valid,//from sram
    output  req_upld_t                                                      fifo_wrreq,
    output  logic                                                           fifo_wrvalid
);


//buffer for req from mm_allocator
    req_upld_t  wrreq_buf[(MST_NUM * MST_NUM) -1 :0];
    logic       wrvalid_buf[(MST_NUM * MST_NUM) - 1:0];
    req_upld_t  rdreq_buf[(MST_NUM * MST_NUM) -1 :0];
    logic       rdvalid_buf[(MST_NUM * MST_NUM) - 1:0];
    int         rdidx[(MST_NUM * MST_NUM) -1 :0];

//buffer for rddata to mm_allocator
    dat_upld_t  rddata_buf[(MST_NUM * MST_NUM) -1 :0];
    logic       rddata_valid_buf[(MST_NUM * MST_NUM) - 1:0];

    int         wr_buf_ptr;
    int         current_wr_buf_ptr;
    int         rd_buf_ptr; 
    int         current_rd_buf_ptr;
    int         rd_data_ptr;   

    int         wrout_buf_ptr;
    int         rdout_buf_ptr;   

//update buffer for req from mm_allocator
    always_comb begin : wr_buffer
        current_wr_buf_ptr = 0;
        for(int i = 0; i < MST_NUM; i++) begin
            if(glbsram_wrvalid[i]) begin
                wrreq_buf[wr_buf_ptr + current_wr_buf_ptr] = glbsram_wrreq[i];
                wrvalid_buf[wr_buf_ptr + current_wr_buf_ptr] = 1'b1;
                current_wr_buf_ptr = current_wr_buf_ptr + 1;
            end
        end
    end

    always_comb begin : rd_buffer
        current_rd_buf_ptr = 0;
        for(int i = 0; i < MST_NUM; i++) begin
            if(glbsram_rdvalid[i]) begin
                rdreq_buf[rd_buf_ptr + current_rd_buf_ptr] = glbsram_rdreq[i];
                rdvalid_buf[rd_buf_ptr + current_rd_buf_ptr] = 1'b1;
                current_rd_buf_ptr = current_rd_buf_ptr + 1;
                rdidx[rd_buf_ptr + current_rd_buf_ptr] = i; //record which req is from which master
            end
        end
    end

// update ptr
    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            wr_buf_ptr <= 0;
        end else begin
            if(current_wr_buf_ptr > 0 && wr_buf_ptr + current_wr_buf_ptr < (MST_NUM * MST_NUM)) begin
                wr_buf_ptr <= wr_buf_ptr + current_wr_buf_ptr;
            end
            else begin
                wr_buf_ptr <= wr_buf_ptr + current_wr_buf_ptr - (MST_NUM * MST_NUM);
            end
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rd_buf_ptr <= 0;
        end else begin
            if(current_rd_buf_ptr > 0 && rd_buf_ptr + current_rd_buf_ptr < (MST_NUM * MST_NUM)) begin
                rd_buf_ptr <= rd_buf_ptr + current_rd_buf_ptr;
            end
            else begin
                rd_buf_ptr <= rd_buf_ptr + current_rd_buf_ptr - (MST_NUM * MST_NUM);
            end
        end
    end

    //for wrreq to fifo
    always_ff @(posedge clk or negedge rstn) begin 
        if(!rstn) begin
            fifo_wrreq <= '0;
            fifo_wrvalid <= 1'b0;
            wrout_buf_ptr <= 0;
        end else begin
            if(wrvalid_buf[wrout_buf_ptr]) begin
                fifo_wrreq <= wrreq_buf[wrout_buf_ptr];
                fifo_wrvalid <= 1'b1;
                wrvalid_buf[wrout_buf_ptr] <= 1'b0;
                if(wrout_buf_ptr + 1 < (MST_NUM * MST_NUM)) begin
                    wrout_buf_ptr <= wrout_buf_ptr + 1;
                end else begin
                    wrout_buf_ptr <= 0;
                end
            end else begin
                fifo_wrreq <= '0;
                fifo_wrvalid <= 1'b0;
            end
        end
    end

    //for rdreq to fifo
    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fifo_rdreq <= '0;
            fifo_rdvalid <= 1'b0;
            rdout_buf_ptr <= 0;
        end else begin
            if(rdvalid_buf[rdout_buf_ptr]) begin
                fifo_rdreq <= rdreq_buf[rdout_buf_ptr];
                fifo_rdvalid <= 1'b1;           
                rdvalid_buf[rdout_buf_ptr] <= 1'b0;
                if(rdout_buf_ptr + 1 < (MST_NUM * MST_NUM)) begin
                    rdout_buf_ptr <= rdout_buf_ptr + 1;
                end else begin
                    rdout_buf_ptr <= 0;
                end
            end else begin
                fifo_rdreq <= '0;
                fifo_rdvalid <= 1'b0;
            end
        end
    end
    //for rddata from fifo to mm_allocator
    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            glbsram_data <= '0;
            glbsram_data_valid <= '0;
        end else begin
            if(fifo_data_valid) begin
                glbsram_data[rdidx[rd_data_ptr]] <= fifo_data;
                glbsram_data_valid[rdidx[rd_data_ptr]] <= 1'b1;
                if(rd_data_ptr + 1 < (MST_NUM * MST_NUM)) begin
                    rd_data_ptr <= rd_data_ptr + 1;
                end else begin
                    rd_data_ptr <= 0;
                end
            end
        end
    end

endmodule