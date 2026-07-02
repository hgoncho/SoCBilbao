`timescale 1ns / 1ps

// Almacena los Timestamping + MsgID + SeqID

module wrapper_dcfifo_128b_16_opensource 
#(                      
    parameter DSIZE = 128,
    parameter ASIZE = 4
    )(
    input  wire                 rst,    
    input  wire                 wr_clk,
    input  wire                 rd_clk,
    
    input  wire [DSIZE-1 :0]    din,
    input  wire                 wr_en,
    input  wire                 rd_en,
    output wire [DSIZE-1 :0]    dout,
    output wire                 full,
    output wire                 empty,
    
    output wire [ASIZE-1:0]     wr_data_count,
    output wire [ASIZE-1:0]     rd_data_count
);  

    wire [ASIZE:0] wptr_gray;
    wire [ASIZE:0] rptr_gray;
    wire [ASIZE:0] wq2_rptr_gray;
    wire [ASIZE:0] rq2_wptr_gray;
    
    wire [ASIZE:0] wr_count_internal;
    wire [ASIZE:0] rd_count_internal;


    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH("FALSE") // Mantener el comportamiento estándar de lectura
    ) fifo_inst (
        // Dominio de Escritura (Write)
        .wclk   (wr_clk),
        .wrst_n (~rst),       
        .winc   (wr_en),
        .wdata  (din),
        .wfull  (full),
        
        // Dominio de Lectura (Read)
        .rclk   (rd_clk),
        .rrst_n (~rst),      
        .rinc   (rd_en),
        .rdata  (dout),
        .rempty (empty),
        
        .wptr_out     (wptr_gray),
        .rptr_out     (rptr_gray),
        .wq2_rptr_out (wq2_rptr_gray),
        .rq2_wptr_out (rq2_wptr_gray)
    );
    
    // ---------------------------------------------------------
    // Función para convertir de código Gray a Binario
    // ---------------------------------------------------------
    function [ASIZE:0] gray2bin;
        input [ASIZE:0] gray;
        integer i;
        begin
            gray2bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE - 1; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
            end
        end
    endfunction

    // ---------------------------------------------------------
    // Cálculo de contadores a 5 bits
    // ---------------------------------------------------------
    assign wr_count_internal = gray2bin(wptr_gray) - gray2bin(wq2_rptr_gray);
    assign rd_count_internal = gray2bin(rq2_wptr_gray) - gray2bin(rptr_gray);

    // ---------------------------------------------------------
    // Truncamiento de la salida a 4 bits [3:0] (0 a 15)
    // ---------------------------------------------------------
    assign wr_data_count = wr_count_internal[ASIZE-1:0];
    assign rd_data_count = rd_count_internal[ASIZE-1:0];
    
endmodule