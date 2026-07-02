module picorv32_wb_adapter (
    input clk,
    input resetn,
    
    // Wishbone Master Interface
    output wb_stb_o,           
    output wb_cyc_o,           
    output wb_we_o,            
    output [31:0] wb_adr_o,    
    output [31:0] wb_dat_o,    
    output [3:0] wb_sel_o,     
    input wb_ack_i,
    input [31:0] wb_dat_i,
    
    // Native PicoRV32 Memory Interface
    input mem_valid,
    input mem_instr,
    output mem_ready,           
    input [31:0] mem_addr,
    input [31:0] mem_wdata,
    input [3:0] mem_wstrb,
    output [31:0] mem_rdata    
);

    reg ack_read;
    reg ack_write;
    
    wire mem_wr = |mem_wstrb;  // Operacion de escritura si hay algun strobe activo
    wire xfer_done = mem_valid & mem_ready;
    
    // Se\F1ales de Wishbone (usar assign porque son wire)
    assign wb_stb_o = mem_valid & ((mem_wr & ~ack_write) | (~mem_wr & ~ack_read));
    assign wb_cyc_o = mem_valid & ((mem_wr & ~ack_write) | (~mem_wr & ~ack_read));
    assign wb_we_o = mem_wr;
    assign wb_adr_o = mem_addr;
    assign wb_dat_o = mem_wdata;
    assign wb_sel_o = mem_wstrb;
    
    // Se\F1al ready cuando recibimos ACK
    assign mem_ready = wb_ack_i;
    assign mem_rdata = wb_dat_i;
    
    always @(posedge clk) begin
        if (!resetn) begin
            ack_read <= 1'b0;
            ack_write <= 1'b0;
        end else begin
            // Registrar cuando completamos una transferencia de escritura
            if (wb_ack_i & wb_stb_o & wb_we_o)
                ack_write <= 1'b1;
                
            // Registrar cuando completamos una transferencia de lectura
            if (wb_ack_i & wb_stb_o & ~wb_we_o)
                ack_read <= 1'b1;
                
            // Limpiar flags cuando la transacci\F3n termine
            if (xfer_done | ~mem_valid) begin
                ack_read <= 1'b0;
                ack_write <= 1'b0;
            end
        end
    end

endmodule

