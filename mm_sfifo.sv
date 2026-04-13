//=============================================================================
// Author:      tangpu
// Email:       tangpu2015@phytium.com.cn
// Date:        2026-03-24
// Description: For multiple mst rd/wr data check
//=============================================================================

    module mm_sfifo #(
        parameter DATA_WIDTH = 8,
        parameter FIFO_DEPTH = 16,
        parameter type DATA_TYPE = logic [DATA_WIDTH-1:0]
    ) (
        input bit                                               clk,
        input bit                                               rst_n,
        input logic                                             wr_en,
        input logic                                             rd_en,
        input DATA_TYPE                                         wr_data,
        output DATA_TYPE                                        rd_data,
        output logic                                            full,
        output logic                                            empty
    );

        localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

        DATA_TYPE fifo_mem [FIFO_DEPTH-1:0];
        logic [ADDR_WIDTH-1:0] wr_ptr;
        logic [ADDR_WIDTH-1:0] rd_ptr;

        always_ff @(posedge clk) begin
            if (~rst_n) begin
                wr_ptr <= 'd0;
            end else if (wr_en && ~full) begin
                fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 'd1;
            end
        end

        assign rd_data = fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];

        always_ff @(posedge clk) begin
            if (~rst_n) begin
                rd_ptr <= 'd0;
            end else if (rd_en && ~empty) begin
                rd_ptr <= rd_ptr + 'd1;
            end 
        end

        assign full = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) &&
                      (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
        assign empty = (wr_ptr == rd_ptr);  

    endmodule