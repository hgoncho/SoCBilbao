#include "ha1588.h"
#include "simpleuart.h"  

// --- REGISTROS HARDWARE (UART) ---
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data   (*(volatile uint32_t*)0x02000008)


void inituart()
{
	#ifdef SIM
        reg_uart_clkdiv = 40;   // ~1.25 Mbps en sim (10x más rápido)
    #else
        reg_uart_clkdiv = 434;  // 115200 bps en real
    #endif

}


// ============================================================================
// FUNCIONES DE TRANSMISIÓN (TX)
// ============================================================================
void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}


void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}


void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
    char buffer[10]; // 32 bits max = 4294967295 (10 dígitos)
    int i = 0;

    if (v == 0) {
        putchar('0');
        return;
    }

    // Extraer los dígitos del menos al más significativo
    while (v > 0) {
        buffer[i++] = (v % 10) + '0';
        v /= 10;
    }

    // Imprimir en el orden correcto (al revés)
    while (i > 0) {
        putchar(buffer[--i]);
    }
}


// ============================================================================
// FUNCIONES DE RECEPCIÓN (RX)
// ============================================================================
int32_t read_log(){
    int32_t c = reg_uart_data;
    return c;
}


char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	//reg_leds = ~0;

	if (prompt)
		print(prompt);

	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 12000000) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
			//reg_leds = ~reg_leds;
		}
		c = reg_uart_data;
	}

	//reg_leds = 0;
	return c;
}


char getchar()
{
	return getchar_prompt(0);
}


// ============================================================================
// FUNCIONES DE PRINT PTP
// ============================================================================
void print_saved_index_ptp(void) {
    print("\n--- VOLCADO DE TIEMPOS PTP Y PAQUETES RX ---\n");
    if (ptp_rx_count == 0) {
        print("No hay paquetes guardados.\n");
    } else {
        for (uint32_t i = 0; i < ptp_rx_count; i++) {
            print("Pk["); print_dec(i+1); print("] MsgID: ");
            print_dec(ptp_rx_history[i].msg_id);
            print(" | SeqID: ");
            print_dec(ptp_rx_history[i].seq_id);
            print(" -> Timestamping: ");
            print_dec(ptp_rx_history[i].sec_ll); print("s ");
            print_dec(ptp_rx_history[i].sec_hl); print("s ");
            print_dec(ptp_rx_history[i].nsec); print("ns");
			print(" -> Timestamping master: ");
			print_dec(ptp_rx_history[i].sec_ll_master); print("s ");
            print_dec(ptp_rx_history[i].sec_hl_master); print("s ");
            print_dec(ptp_rx_history[i].nsec_master); print("ns\n");
            
            // --- NUEVO: IMPRIMIR LOS DATOS HEXADECIMALES ---
            print("      Longitud Real: "); 
            print_dec(ptp_rx_history[i].packet_len); print(" bytes\n");
            print("\n\n");
        }

		print("--------------------------------------------\n\n");

		for (uint32_t i = 0; i < ptp_rx_count_generic; i++) {
            print("Pk["); print_dec(i+1); print("] MsgID: ");
            print_dec(ptp_rx_generic[i].msg_id);
            print(" | SeqID: ");
            print_dec(ptp_rx_generic[i].seq_id);
            print(" -> Timestamping: ");
            print_dec(ptp_rx_generic[i].sec_ll); print("s ");
            print_dec(ptp_rx_generic[i].sec_hl); print("s ");
            print_dec(ptp_rx_generic[i].nsec); print("ns");
			print(" -> Timestamping master: ");
			print_dec(ptp_rx_generic[i].sec_ll_master); print("s ");
            print_dec(ptp_rx_generic[i].sec_hl_master); print("s ");
            print_dec(ptp_rx_generic[i].nsec_master); print("ns\n");
            
            // --- NUEVO: IMPRIMIR LOS DATOS HEXADECIMALES ---
            print("      Longitud Real: "); 
            print_dec(ptp_rx_generic[i].packet_len); print(" bytes\n");
            print("\n\n");
        }
    }
    print("--------------------------------------------\n\n");
}


void print_saved_message (uint32_t i){
    print("\n--- Mensaje guardado en el slot => ");
	print_dec(i + 1);
	print(" ---\n");

    if (ptp_rx_count <= i) {
        print("No hay paquetes guardado en ese slot\n");
    } else {
            print("Pk["); print_dec(i+1); print("] MsgID: ");
            print_dec(ptp_rx_history[i].msg_id);
            print(" | SeqID: ");
            print_dec(ptp_rx_history[i].seq_id);
            print(" -> Timestamping: ");
            print_dec(ptp_rx_history[i].sec_ll); print("s ");
            print_dec(ptp_rx_history[i].sec_hl); print("s ");
            print_dec(ptp_rx_history[i].nsec); print("ns");
			print(" -> Timestamping master: ");
			print_dec(ptp_rx_history[i].sec_ll_master); print("s ");
            print_dec(ptp_rx_history[i].sec_hl_master); print("s ");
            print_dec(ptp_rx_history[i].nsec_master); print("ns\n");

            print("      Longitud Real: "); 
            print_dec(ptp_rx_history[i].packet_len); print(" bytes\n");
            print("\n\n");

			print("      Mensaje ("); 
            print_dec(ptp_rx_history[i].packet_len); print(" bytes totales):\n      ");
            
            uint16_t limit = (ptp_rx_history[i].packet_len < SAVED_PAYLOAD_SIZE) ? ptp_rx_history[i].packet_len : SAVED_PAYLOAD_SIZE;
            for(int j = 0; j < limit; j++){
                print_hex(ptp_rx_history[i].payload[j], 2);
                print(" ");
                // Salto de línea cada 16 bytes para que quede como una tabla limpia
                if((j + 1) % 16 == 0 && j != (limit - 1)) {
                    print("\n      "); 
                }
            }
            print("\n\n");

			print("--------------------------------------------\n\n");

			print("Pk["); print_dec(i+1); print("] MsgID: ");
            print_dec(ptp_rx_generic[i].msg_id);
            print(" | SeqID: ");
            print_dec(ptp_rx_generic[i].seq_id);
            print(" -> Timestamping: ");
            print_dec(ptp_rx_generic[i].sec_ll); print("s ");
            print_dec(ptp_rx_generic[i].sec_hl); print("s ");
            print_dec(ptp_rx_generic[i].nsec); print("ns");
			print(" -> Timestamping master: ");
			print_dec(ptp_rx_generic[i].sec_ll_master); print("s ");
            print_dec(ptp_rx_generic[i].sec_hl_master); print("s ");
            print_dec(ptp_rx_generic[i].nsec_master); print("ns\n");

            print("      Longitud Real: "); 
            print_dec(ptp_rx_generic[i].packet_len); print(" bytes\n");
            print("\n\n");

			print("      Mensaje ("); 
            print_dec(ptp_rx_generic[i].packet_len); print(" bytes totales):\n      ");
            
            uint16_t limit2 = (ptp_rx_generic[i].packet_len < SAVED_PAYLOAD_SIZE) ? ptp_rx_generic[i].packet_len : SAVED_PAYLOAD_SIZE;
            for(int j = 0; j < limit2; j++){
                print_hex(ptp_rx_generic[i].payload[j], 2);
                print(" ");
                // Salto de línea cada 16 bytes para que quede como una tabla limpia
                if((j + 1) % 16 == 0 && j != (limit2 - 1)) {
                    print("\n      "); 
                }
            }
            print("\n\n");
    }
    print("--------------------------------------------\n\n");
}


void print_ptp_time(ptp_time_t t) {
    if (t.sec < 0) {
        if (t.ns > 0) { 
			print("-"); 
			print_dec(-(t.sec + 1)); 
			print("s, "); 
			print_dec(1000000000 - t.ns); 
			print("ns\n"); 
		}
        else { 
			print("-"); 
			print_dec(-t.sec); 
			print("s, 0ns\n"); 
		}
    } else { 
		print_dec(t.sec); 
		print("s, "); 
		print_dec(t.ns); 
		print("ns\n"); 
	}
}


