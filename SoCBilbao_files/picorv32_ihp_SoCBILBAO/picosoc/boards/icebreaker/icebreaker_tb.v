/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1 ns / 1 ps

module testbench_ice;
	reg clk;
	reg ser_rx;
	always #5 clk = (clk === 1'b0);

	localparam ser_half_period = 53;
	event ser_sample;

	initial begin
		$dumpfile("icebreaker/testbench_ice.vcd");
		$dumpvars(0, testbench_ice);
		ser_rx = 1'b1; // UART idle state
			
		repeat (8) begin
			repeat (50000) @(posedge clk);
			//$display("+50000 cycles");
		end

	        // 1. Enviar ENTER para pasar el prompt inicial
		send_char(8'h0D); // 0x0D es '\r' en ASCII
		
		repeat (8) begin
			repeat (50000) @(posedge clk);
			//$display("+50000 cycles");
		end		

		$display("Simulación finalizada.");
		$finish;
		// Esperar a que se imprima el menú
		repeat (35) begin
			repeat (50000) @(posedge clk);
			//$display("+50000 cycles");
		end

		// 2. Enviar un comando (por ejemplo, '1' para leer Flash ID)
		send_char("e");
		repeat (6) begin
			repeat (50000) @(posedge clk);
		end
		send_char("H");
		repeat (6) begin
			repeat (50000) @(posedge clk);
		end
		send_char("o");
		repeat (6) begin
			repeat (50000) @(posedge clk);
		end
		send_char("l");
		repeat (6) begin
			repeat (50000) @(posedge clk);
		end
		send_char("a");
		repeat (6) begin
			repeat (50000) @(posedge clk);
		end
		send_char("!");

		// Esperar para ver la respuesta en la consola
		repeat (35) begin
			repeat (50000) @(posedge clk);
			//$display("+50000 cycles");
		end
		    
		// 3. Probar el modo Echo (comando 'e')
		send_char("e");
		repeat (1000) @(posedge clk);
		send_char("H");
		send_char("o");
		send_char("l");
		send_char("a");
		send_char("!"); // El comando 'e' sale con '!' según tu firmware

		//repeat (6) begin
		//	repeat (50000) @(posedge clk);
		//	$display("+50000 cycles");
		//end
		
		repeat (50000) @(posedge clk);
		$display("Simulación finalizada por límite de tiempo.");
		$finish;
	end

	integer cycle_cnt = 0;

	always @(posedge clk) begin
		cycle_cnt <= cycle_cnt + 1;
	end

	wire led1, led2, led3, led4, led5;
	wire ledr_n, ledg_n;

	wire [6:0] leds = {!ledg_n, !ledr_n, led5, led4, led3, led2, led1};

	wire ser_tx;
	
	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire flash_io2;
	wire flash_io3;

	always @(leds) begin
		#1 $display("%b", leds);
	end

	icebreaker #(
		// We limit the amount of memory in simulation
		// in order to avoid reduce simulation time
		// required for intialization of RAM
		.MEM_WORDS(256)
	) uut (
		.clk      (clk      ),
		.led1     (led1     ),
		.led2     (led2     ),
		.led3     (led3     ),
		.led4     (led4     ),
		.led5     (led5     ),
		.ledr_n   (ledr_n   ),
		.ledg_n   (ledg_n   ),
		.ser_rx   (ser_rx   ),
		.ser_tx   (ser_tx   ),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.flash_io2(flash_io2),
		.flash_io3(flash_io3)
	);

	spiflash spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(flash_io2),
		.io3(flash_io3)
	);

	reg [7:0] buffer;

	always begin
		@(negedge ser_tx);

		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // start bit

		repeat (8) begin
			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			buffer = {ser_tx, buffer[7:1]};
			-> ser_sample; // data bit
		end

		repeat (ser_half_period) @(posedge clk);
		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // stop bit

		if (buffer == 8'h0A) begin
			$display(""); // Si es salto de línea, bajar de renglón
		end else if (buffer >= 32 && buffer < 127) begin
			$write("%c", buffer); // Imprimir carácter ASCII
			$fflush();            // Forzar salida a consola
		end
	end

	//Funcion para escribir por UART(RX)
	task send_char;
	    input [7:0] char;
	    integer i;
	    begin
		// Bit de inicio (Start bit)
		ser_rx = 0;
		repeat (2 * ser_half_period) @(posedge clk);

		// 8 Bits de datos (LSB first)
		for (i = 0; i < 8; i = i + 1) begin
		    ser_rx = char[i];
		    repeat (2 * ser_half_period) @(posedge clk);
		end

		// Bit de parada (Stop bit)
		ser_rx = 1;
		repeat (2 * ser_half_period) @(posedge clk);
		
		$display("Sent character: '%c' (0x%h)", char, char);
	    end
	endtask



endmodule
