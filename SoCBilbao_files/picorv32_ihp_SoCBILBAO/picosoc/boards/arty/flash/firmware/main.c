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

#include <stdint.h>
#include <stdbool.h>

#include "minimac2.h"
#include "ha1588.h"
#include "simpleuart.h"
#include "spiflash.h"
#include "ptp_packets_example.h"


//---------------------------------------------------------------
// REGISTROS PERIFERICOS
//---------------------------------------------------------------

#define reg_irq_status (*(volatile uint32_t*)0x02000010)
#define reg_irq_mask   (*(volatile uint32_t*)0x02000014)

#define reg_leds (*(volatile uint32_t*)0x03000000)


// --------------------------------------------------------
// INTERRUPCIONES
//----------------------------------------------------------
// Definición compatible para PicoRV32
static inline uint32_t irq_setmask(uint32_t mask) {
    uint32_t old_mask;
    // Opcode para picorv32_irqmask: 0x0600000b
    asm volatile (".word 0x0600000b" : "=r"(old_mask) : "0"(mask));
    return old_mask;
}


static inline uint32_t irq_setie(uint32_t ie) {
    uint32_t old_ie;
    // Opcode para picorv32_getq q, q2: 0x0200000b (donde q es el registro destino)
    // Opcode para picorv32_setq q2, q: 0x0000000b (donde q es el registro origen)
    // Usamos registros temporales compatibles
    asm volatile (".word 0x0200000b" : "=r"(old_ie) : "r"(0)); // getq_insn %0, q2
    asm volatile (".word 0x0000000b" : : "r"(ie));              // setq_insn q2, %0
    return old_ie;
}


// Definición de la rutina de interrupción (ISR)
// El PicoRV32 busca una función llamada 'irq' si el compilador está configurado así,
// o una función asociada al vector de interrupción.
uint32_t *irq(uint32_t *regs, uint32_t irqs) {
    /* 'irqs' contiene los bits que están activos en la línea IRQ del procesador.*/

    uint32_t status = reg_irq_status;
    uint32_t mask = reg_irq_mask;
    uint32_t active_irqs = status & mask;

    if (active_irqs & irq_bit_minimac2_rx) {			// Interrupcion de Ethernet RX
		RX_active = 1; 	

		reg_irq_mask = reg_irq_mask & ~irq_bit_minimac2_rx;       
        reg_irq_status = irq_bit_minimac2_rx;

		//reg_leds = reg_leds ;
		//reg_leds ^= 0x02;
    }

    if (active_irqs & irq_bit_minimac2_tx) { 		// Interrupción de Ethernet TX
		reg_irq_status = irq_bit_minimac2_tx;  

		TX_active = 1;  
		//reg_leds ^= 0x01;
		
    }

    return regs; 
}


// --------------------------------------------------------
// GESTION DE TIEMPOS PTP
//----------------------------------------------------------
ptp_time_t t1, t2, t3, t4;

ptp_time_t diff_21, diff_43;

void tx_timestamping_timeout(int timeout, uint8_t *payload_vec, int dips_timestamping){
	uint32_t tx_timeout_cnt = 0;
	while(TX_active == 0 && tx_timeout_cnt < timeout) {
		tx_timeout_cnt++;
	}

	if (tx_timeout_cnt >= timeout) {
		print("[ERROR] El hardware MAC no responde (TX Timeout)!\n");
	} else {
		TX_active = 0;
		ha_check_tx_timestamp(payload_vec, dips_timestamping);
	}
}


// --------------------------------------------------------
// DATOS ENVIO MINIMAC2
//----------------------------------------------------------
uint8_t buffer_rx [MAX_BUFFER];

uint16_t len_RX = 0;



// --------------------------------------------------------
// MAQUINA DE ESTADOS SYNC PTP
//----------------------------------------------------------
typedef enum {
    PTP_STATE_WAIT_SYNC = 0,
    PTP_STATE_WAIT_FOLLOW_UP,
    PTP_STATE_WAIT_DELAY_RESP
} ptp_state_t;

ptp_state_t ptp_sync_estado = PTP_STATE_WAIT_SYNC;
uint32_t ptp_timeout = 0;
#define TIMEOUT_MAX 800000



// --------------------------------------------------------
// MAIN
//----------------------------------------------------------
#define controlador_P 86
#define controlador_I 2
int32_t acumulador_integral = 0;


int envio_pendiente = 0;

int send_TX = 0;
int log_active = 1;
int log_active_ant = 1;
int rst_ptp = 0;
int test_rtc = 0;
int status_tsu = 0;
int sync_ptp_master = 0;
int sync_ptp_slave_nmaster = 2;			// 1 slave - 0 master - 2 nada
int send_delay_request = 0;
int send_delay_reply = 0;
int times_sync = 0;
int trigger_ptp_calc = 0;

int auto_sync = 0;
uint32_t ultimo_ciclo_sync = 0;
uint32_t ciclos_actuales = 0;

uint32_t c_start, c_end;

int cnt = 0;
int error_index = 0;


int print_index = 0;
int print_message = 0;
int index = 0;
char tecla = '0';

uint16_t len_TX;


uint8_t payload_vector[10];

uint8_t time1_m[10];
uint8_t time2_s[10];
uint8_t time3_s[10];
uint8_t time4_m[10];

uint32_t errores_abs_ns[70];
//uint32_t errores_abs_s[70];


void main()
{
	//Divisor = FrecuenciaReloj/Baudios
	
    inituart();

	reg_leds = 0xF;
	

	print("Booting..\n");
		
	//set_flash_qspi_flag();		// COMANDO SPIFLASH SIMULADA
	//set_flash_mode_quad();		// Funciona solo en la ARTY(COM10) falla en la ARTY(COM8)

	minimac2_init();
	ha_init_rtc();
	ha_init_tsu();

	//Inicio de interrupciones
	minimac2_init_interrupts();

	irq_setmask(0); 
	irq_setie(1);

	while (getchar_prompt("Press ENTER to continue..\n") != '\r');
	reg_leds = 0x0;

	print("Esperando comando...\n");

	while(1){	

		// Gestion de recepcion de paquete
		if (RX_active == 1) {
			RX_active = 0;

			//while (reg_SLOT0_CTL == RX_STATE_PENDING || reg_SLOT1_CTL == RX_STATE_PENDING) {
			
				len_RX = minimac2_process_rx(buffer_rx);

				uint16_t ethertype = (buffer_rx[20] << 8) | buffer_rx[21];

				if (ethertype == 0x88F7) {
					// SOY MAESTRO
					if (sync_ptp_slave_nmaster == 0){
						// Delay request
						if (buffer_rx[22] == 0x01) {
							//reg_leds ^= 0x04;
							ha_check_rx_timestamp(buffer_rx, len_RX, time4_m);
							send_delay_reply = 1;
						}
					}

					// SOY ESCLAVO
					switch (ptp_sync_estado){
						case PTP_STATE_WAIT_SYNC:
							if (buffer_rx[22] == 0x00) {
								//reg_leds ^= 0x04;
								ha_check_rx_timestamp(buffer_rx, len_RX, time2_s);
								sync_ptp_slave_nmaster = 1;			// SOY ESCLAVO
								ptp_sync_estado = PTP_STATE_WAIT_FOLLOW_UP;
								ptp_timeout = 0;

							}else {
								// Caso que no tenga que ver con la sync PTP
								reg_leds ^= 0x04;
								ha_check_rx_timestamp(buffer_rx, len_RX, payload_vector);
							}
							break;

						
						case PTP_STATE_WAIT_FOLLOW_UP:
							if (buffer_rx[22] == 0x08) {
								//reg_leds ^= 0x04;

								for (int i = 0; i < 10; i++) {
									time1_m[i] = buffer_rx[8 + 6 + 6 + 2 + 34 + i];
								}
								ha_check_rx_timestamp(buffer_rx, len_RX, payload_vector);
								send_delay_request = 1;
								ptp_sync_estado = PTP_STATE_WAIT_DELAY_RESP;
								ptp_timeout = 0;
							}
							break;

						case PTP_STATE_WAIT_DELAY_RESP:
							if (buffer_rx[22] == 0x09) {
								//reg_leds ^= 0x04;

								for (int i = 0; i < 10; i++) {
									time4_m[i] = buffer_rx[8 + 6 + 6 + 2 + 34 + i];
								}
								ha_check_rx_timestamp(buffer_rx, len_RX, payload_vector);
								trigger_ptp_calc = 1; // Disparar cálculos
								ptp_sync_estado = PTP_STATE_WAIT_SYNC;
							}
							break;
						
						default:
							break;

					}


				}else{

					print("Recibido paquete no 88F7\n");

					ha_check_rx_timestamp(buffer_rx, len_RX, payload_vector);
					
				}
				
			//}

			//print("Paquete recibido\n");
		}

		// Timeout de sync PTP
        if (ptp_sync_estado != PTP_STATE_WAIT_SYNC) {
            ptp_timeout++;
            if (ptp_timeout > TIMEOUT_MAX) {
                print("[PTP] Timeout! Abortando sincronizacion.\n");
                ptp_sync_estado = PTP_STATE_WAIT_SYNC;
            }
        }

		// Calculo de tiempos de sync (delay y offset)
		if (trigger_ptp_calc){
			int step = 0;
			
			t1 = extraer_tiempo(time1_m);
			t2 = extraer_tiempo(time2_s);
			t3 = extraer_tiempo(time3_s);
			t4 = extraer_tiempo(time4_m);

			diff_21 = ptp_sub_diff(t2, t1);
			diff_43 = ptp_sub_diff(t4, t3);

			// Calculo delay y offset
			delay_ptp  = ptp_div2(ptp_add_diff(diff_43, diff_21));
			offset = ptp_div2(ptp_sub_diff(diff_21, diff_43));

			if (error_index < 69){
                error_index++;

			}else{
				error_index = 0;
			}	
			
			errores_abs_ns[error_index] = offset.ns;
			//errores_abs_s[error_index] = offset.sec;

			if (offset.sec > 0 || offset.sec < -1) {
			    step = 1;
			} else {
			    if (offset.sec == -1) {
			        errores_abs_ns[error_index] = 1000000000 - offset.ns; 
			    }

			    if (errores_abs_ns[error_index] > 1000000) {
			        step = 1;
			    }
			}

			// Comprobamos si hace falta sincronizar o sintonizar
			if (step) {
				uint32_t sh, sl, nh, nl;

				// Compensamos los ciclos de calculo
				__asm__ volatile ("rdcycle %0" : "=r"(c_start));

				ha_rtc_get_time(&sh, &sl, &nh, &nl);
				uint32_t ns_l = sl - offset.sec;
				int32_t n_ns = (int32_t)nh - offset.ns;
				if (n_ns < 0) { 
					n_ns += 1000000000; 
					ns_l -= 1; 
				}

				__asm__ volatile ("rdcycle %0" : "=r"(c_end));
				uint32_t ciclos_perdidos = c_end - c_start;
				uint32_t tiempo_perdido_ns = ciclos_perdidos * 20; 

				// Compensamos añadiendo el tiempo perdido a los nanosegundos
				n_ns += tiempo_perdido_ns;
				if (n_ns >= 1000000000) {
					n_ns -= 1000000000;
					ns_l += 1;
				}

				// Actualizacion de tiempos 
				ha_rtc_set_time(sh, ns_l, (uint32_t)n_ns, nl);

				acumulador_integral = 0;

			}else{
				// Controlador PI para aumantar/reducir la velocidad de reloj
				int32_t error_ns = offset.ns;
				int32_t error_real;

				if (offset.sec == -1) {	
					error_ns = 1000000000 - offset.ns;
					error_real = error_ns;
				}else{	
					error_real = -error_ns;
				}

				int32_t termino_P = error_real * controlador_P;

				acumulador_integral += (error_real * controlador_I);

				// Limitamos para evitar el desbordamiento
				if (acumulador_integral > 500000000) {
				    acumulador_integral = 500000000;
				} else if (acumulador_integral < -500000000) {
				    acumulador_integral = -500000000;
				}

				int32_t correccion_total = termino_P + acumulador_integral;

				uint32_t base_per_h; 
				uint32_t base_per_l;

				if (correccion_total >= 0) {
					// Reloj mas rapido
					base_per_h = 0x20; 
					base_per_l = (uint32_t)correccion_total; 
					
				} else {
					// Reloj mas despacio
					base_per_h = 0x1F; // Bajamos a 19 ns enteros
					base_per_l = (uint32_t)correccion_total; 
				}
			    
				// Cambiamos la frecuencia permanentemente
				ha_rtc_set_period(base_per_h, base_per_l);

			}
			//print("Timepos actualizados");

			// Envio con sync activa
			if (envio_pendiente == 1) {
				uint8_t mis_datos[12] = "Hola Mundo!";
				int len_datos = gen_trama(mac_all, 0x1234, mis_datos, 11);
				minimac2_send(custom_tx_buffer, len_datos);

				tx_timestamping_timeout(500000, payload_vector, 1);

				print("Enviado slave paquete no 88F7\n");
				
				envio_pendiente = 0; 
			}

			trigger_ptp_calc = 0;
			if (!auto_sync) log_active = 1;
        }

		// SOY ESCLAVO - envio delay request
		if (send_delay_request){
			// Envio de sync
			payload_ptp_sync[0] = 0x01;
			len_TX = gen_trama(mac_all, 0x88F7, payload_ptp_sync, 44);
			minimac2_send(custom_tx_buffer, len_TX);

			tx_timestamping_timeout(500000, time3_s, 0);

			send_delay_request = 0;
		}

		// SOY MAESTRO - Envio delay reply (time4)
		if (send_delay_reply){
			// Envio de sync
			payload_ptp_sync[0] = 0x09;
			for (int i = 0; i < 10; i++) {
				payload_ptp_sync[34 + i] = time4_m[i];
			}

			len_TX = gen_trama(mac_all, 0x88F7, payload_ptp_sync, 44);
			minimac2_send(custom_tx_buffer, len_TX);

			tx_timestamping_timeout(500000, payload_vector, 0);

			// Envio con sync activa
			if (envio_pendiente == 1) {
				payload_ptp_sync[0] = 0xFF;

				int len_datos = gen_trama(mac_all, 0x88F7, payload_ptp_sync, 44);
				minimac2_send(custom_tx_buffer, len_datos);
				
				envio_pendiente = 0; 

				tx_timestamping_timeout(500000, payload_vector, 1);
				

				print("Enviado master paquete no 88F7\n");
			}

			
			
			send_delay_reply = 0;
		}

		// SOY MAESTRO - inicio sincronizacion
		if (sync_ptp_master) {
			sync_ptp_slave_nmaster = 0;

			// Envio de sync
			payload_ptp_sync[0] = 0x00; 
			len_TX = gen_trama(mac_all, 0x88F7, payload_ptp_sync, 44);
			minimac2_send(custom_tx_buffer, len_TX);

			tx_timestamping_timeout(500000, time1_m, 0);

			delay(10);

			// Paquete con timestamping
			payload_ptp_sync[0] = 0x08; 
			for (int i = 0; i < 10; i++) {
				payload_ptp_sync[34 + i] = time1_m[i];
			}

			len_TX = gen_trama(mac_all, 0x88F7, payload_ptp_sync, 44);
			
			minimac2_send(custom_tx_buffer, len_TX);
			
			tx_timestamping_timeout(500000, payload_vector, 0);

			// print("longiutd TX: ");
			// print_dec(len_RX);

			sync_ptp_master = 0;
			if (!auto_sync) {
				log_active = 1; 
				print("\n");
			}
		}

		// Envio de mensaje generico de pruebas
		if ((send_TX) && (!auto_sync)) {
			minimac2_send(packet_prueba_100, ((uint16_t)104));

			send_TX = 0;
		}

		// Gestion de IRQ de TX
		if(TX_active){
			ha_check_tx_timestamp(payload_vector, 1);
			
			TX_active = 0;
			log_active = 1; 	
			//print("\n"); 
			
		}

		// Sincronizacion automatica (8 veces/s)
		if (auto_sync){	
			
			__asm__ volatile ("rdcycle %0" : "=r"(ciclos_actuales));
			
			// 6.250.000 ciclos = 125 milisegundos a 50 MHz
			if ((ciclos_actuales - ultimo_ciclo_sync) >= 6250000) {
				ultimo_ciclo_sync = ciclos_actuales;
				sync_ptp_master = 1; 
				cnt ++;
			} 
		}

		// Timepos, delay y offset de sync PTP
		if (times_sync){
			print("Tiempos de sincronización: \n");
			if (sync_ptp_slave_nmaster == 0){
				print("SOY MAESTRO\n");
			} else if (sync_ptp_slave_nmaster == 1){
				print("SOY ESCLAVO\n");
			}

			print("time1: \n");
			for (int i = 0; i < 10; i++) {
				print_hex(time1_m[i], 2);
				print(" ");
			}
			print("\n");
			print_ptp_time(t1);
			print("\n");

			print("time2: \n");
			for (int i = 0; i < 10; i++) {
				print_hex(time2_s[i], 2);
				print(" ");
			}
			print("\n");
			print_ptp_time(t2);
			print("\n");

			print("time3: \n");
			for (int i = 0; i < 10; i++) {
				print_hex(time3_s[i], 2);
				print(" ");
			}
			print("\n");
			print_ptp_time(t3);
			print("\n");

			print("time4: \n");
			for (int i = 0; i < 10; i++) {
				print_hex(time4_m[i], 2);
				print(" ");
			}
			print("\n");
			print_ptp_time(t4);
			print("\n");

			print("Offset: \n");
			print_ptp_time(offset);
			print("\n");

			print("Delay: \n");
			print_ptp_time(delay_ptp);
			print("\n");

			print("Ciclos calculados de diff: ");
			print_dec(c_end - c_start);
			print(" ciclos \n");

			print("Total de calculos de error ns: \n");
			print_dec(error_index);
			print("\n");

			for (int i = 0; i < error_index; i++) {
				print_dec(errores_abs_ns[i]);
				print(" ");
			}
			print("\n\n"); 

			// print("Total de calculos de error s: \n");
			// for (int i = 0; i < error_index; i++) {
			// 	print_dec(errores_abs_s[i]);
			// 	print(" ");
			// }
			// print("\n"); 

			times_sync = 0;  
			log_active = 1; 	
			print("\n"); 
		}

		// Resumen de mensajes recibidos
		if (print_index){	
			print_saved_index_ptp();

		    print_index = 0;  
			log_active = 1; 	
			print("\n");    
		}

		// Reset de RTC y de TSU
		if (rst_ptp){	
			ha_init_rtc();
			ha_init_tsu();

			ha_rtc_test_read_time();

		    rst_ptp = 0;  
			log_active = 1; 
			print("\n");	    
		}

		// Test de tiempo actual del RTC
		if (test_rtc){	
			ha_rtc_test_read_time();

		    test_rtc = 0;  
			log_active = 1; 
			print("\n");	    
		}

		// Mensajes recibidos por RX
		if (print_message){	
			print_saved_message(index);

		    print_message = 0;  
			log_active = 1; 
			print("\n");	    
		}

		// Log UART
		if (log_active) {
			int32_t c = read_log();
			if (c != -1){
				switch (c) {
					case 'i':
					case 'I':
						print("Recibido comando de resumen buffer RX\n");
						print_index = 1;
						log_active = 0;
						break;

					case 'y':
					case 'Y':
						print("Recibido comando de sincronización PTP\n");
						sync_ptp_master = 1;
						log_active = 0;
						break;

					case 'd':
					case 'D':
						print("Recibido comando de borrado buffer RX y error\n");
						ptp_rx_count = 0;
						error_index = 0;
						break;

					case 'r':
					case 'R':
						print("Recibido comando de reinicio ptp\n");
						rst_ptp = 1;
						log_active = 0;
						break;

					case 'x':
					case 'X':
						print("Recibido comando de test RTC PTP\n");
						test_rtc = 1;
						log_active = 0;
						break;

					case 't':
					case 'T':
						print("Recibido comando de tiempos sync\n");
						times_sync = 1;
						log_active = 0;
						break;

					case 's':
					case 'S':
						print("Recibido comando de envio genérico\n");
						if (auto_sync){
							envio_pendiente = 1;
						}else{
							send_TX = 1;
							log_active = 0;
						}
						break;

					case 'z':
					case 'Z':
						if (auto_sync == 0) {
							print("PTP Continuo ENCENDIDO (pulsa 'z' para apagar)\n");
							auto_sync = 1;
							__asm__ volatile ("rdcycle %0" : "=r"(ultimo_ciclo_sync));

						} else {
							print("PTP Continuo APAGADO\n");
							auto_sync = 0;
						}
						break;

					case 'p':
					case 'P':
						tecla = getchar_prompt("Introduce un numero valido (1 - 5):\n");
						if (tecla >= '1' && tecla <= '5') {
							index = tecla - '0' - 1;
							print_message = 1;
						} else {
							print("Num no valido\n");
						}
						break;

					case 'h':
					case 'H':
						print("Recibido comando de help\n");
						print("\n--- COMANDOS DISPONIBLES ---\n");
						print(" [y] - Sync PTP como maestro (una vez)\n");
						print(" [z] - Sincornizacion y sintonizacion (8 veces/s)\n");
						print(" [t] - Tiempos guardados de sync \n");
						print(" [i] - Imprimir resumen del historial PTP RX\n");
						print(" [r] - Reinicio PTP\n");
						print(" [x] - Test RTC PTP \n");
						print(" [p] - Ver el contenido hexadecimal de un paquete (1-5)\n");
						print(" [d] - Resetear/Borrar el buffer RX\n");
						print(" [s] - Forzar el envio de un paquete TX\n");
						print(" [h] - Mostrar este menu de ayuda\n");
						print("----------------------------\n");
						print(" v 2.2 \n");
						print("----------------------------\n");
						break;

					
					default:
						print("Comando no valido...\n");
						break;
				}
			}
		}

	}
	
	print("FIN\n");
	
}
