#include "ha1588.h"
#include "simpleuart.h"  

// --- REGISTROS HARDWARE  (RTC) ---
#define reg_RTC_CTRL       (*(volatile uint32_t*)0x04002000)
#define reg_RTC_SG_H       (*(volatile uint32_t*)0x04002010)
#define reg_RTC_SG_L       (*(volatile uint32_t*)0x04002014)
#define reg_RTC_NS_H       (*(volatile uint32_t*)0x04002018)
#define reg_RTC_NS_L       (*(volatile uint32_t*)0x0400201C)
#define reg_RTC_PER_H      (*(volatile uint32_t*)0x04002020)
#define reg_RTC_PER_L      (*(volatile uint32_t*)0x04002024)
#define reg_RTC_ADJPER_H   (*(volatile uint32_t*)0x04002028)
#define reg_RTC_ADJPER_L   (*(volatile uint32_t*)0x0400202C)
#define reg_RTC_ADJNUM     (*(volatile uint32_t*)0x04002030)

// --- REGISTROS HARDWARE  (TSU) ---
#define reg_TSU_RXCTRL       	(*(volatile uint32_t*)0x04002040)
#define reg_TSU_RX_STATUS       (*(volatile uint32_t*)0x04002044)
#define reg_TSU_RX_SG_HH       	(*(volatile uint32_t*)0x04002050)
#define reg_TSU_RX_SG_HL       	(*(volatile uint32_t*)0x04002054)
#define reg_TSU_RX_NS		   	(*(volatile uint32_t*)0x04002058)
#define reg_TSU_RX_INFO       	(*(volatile uint32_t*)0x0400205C)

#define reg_TSU_TXCTRL       	(*(volatile uint32_t*)0x04002060)
#define reg_TSU_TX_STATUS       (*(volatile uint32_t*)0x04002064)
#define reg_TSU_TX_SG_HH       	(*(volatile uint32_t*)0x04002070)
#define reg_TSU_TX_SG_HL       	(*(volatile uint32_t*)0x04002074)
#define reg_TSU_TX_NS		   	(*(volatile uint32_t*)0x04002078)
#define reg_TSU_TX_INFO       	(*(volatile uint32_t*)0x0400207C)

// --- VALORES DE CONTROL INTERNOS ---
#define RTC_SET_CTRL_0 0x00
#define RTC_GET_TIME   0x01
#define RTC_SET_ADJ    0x02
#define RTC_SET_PERIOD 0x04
#define RTC_SET_TIME   0x08
#define RTC_SET_RESET  0x10

#define RTC_SET_PERIOD_H 0x20  // 20ns for 50MHz
#define RTC_SET_PERIOD_L 0x00

#define TSU_SET_CTRL_0 	0x00
#define TSU_GET_QUE	   	0x01
#define TSU_SET_RST		0x02
#define TSU_MASK_MSGID  0xFF000000  // FF to enable 0x0 to 0x7

// --- VARIABLES GLOBALES  ---
ptp_record_t ptp_rx_history[MAX_PTP_RECORDS];
ptp_record_t ptp_rx_generic[MAX_PTP_RECORDS];

uint32_t ptp_rx_count = 0;
uint32_t ptp_rx_count_generic = 0;

ptp_time_t delay_ptp;
ptp_time_t offset;


// ============================================================================
// FUNCIONES BÁSICAS Y MATEMÁTICAS
// ============================================================================
void delay(int d){
	for(volatile int i=0; i<d; i++);
}


ptp_time_t extraer_tiempo(uint8_t *vector) {
	ptp_time_t r; 
    r.sec  = (vector[2] << 24) | (vector[3] << 16) | (vector[4] << 8) | vector[5];
    r.ns   = (vector[6] << 24) | (vector[7] << 16) | (vector[8] << 8) | vector[9];
	return r;
}


ptp_time_t ptp_sub_diff(ptp_time_t a, ptp_time_t b) {
    ptp_time_t r; 

	r.sec = a.sec - b.sec; 
	r.ns = a.ns - b.ns;

    if (r.ns < 0) { 
		r.ns += 1000000000; 
		r.sec -= 1; 
	}	 
	return r;
}


ptp_time_t ptp_add_diff(ptp_time_t a, ptp_time_t b) {
    ptp_time_t r; 

	r.sec = a.sec + b.sec; 
	r.ns = a.ns + b.ns;

    if (r.ns >= 1000000000) { 
		r.ns -= 1000000000; 
		r.sec += 1; 
	} 
	return r;
}


ptp_time_t ptp_div2(ptp_time_t a) {
    ptp_time_t r; 

    r.sec = a.sec / 2; 
    r.ns = a.ns / 2;

    // Si los segundos son impares (hay resto)
    if (a.sec % 2 != 0) {
        if (a.sec > 0) {
            r.ns += 500000000; // Si es positivo, sumamos medio segundo
        } else {
            r.ns -= 500000000; // Si es negativo, RESTAMOS medio segundo
        }
    }

    // Normalizamos el resultado
    if (r.ns < 0) { 
        r.ns += 1000000000; 
        r.sec -= 1; 
    } 
    else if (r.ns >= 1000000000) { 
        r.ns -= 1000000000; 
        r.sec += 1; 
    }
    
    return r;
}


// ============================================================================
// FUNCIONES RTC (RELOJ)
// ============================================================================
void ha_rtc_set_period(uint32_t per_h, uint32_t per_l) {
    reg_RTC_PER_H = per_h;
    reg_RTC_PER_L = per_l;

	reg_RTC_CTRL = RTC_SET_CTRL_0; 
    reg_RTC_CTRL = RTC_SET_PERIOD;
}


void ha_rtc_set_time(uint32_t sec_h, uint32_t sec_l, uint32_t ns_h, uint32_t ns_l) {
    reg_RTC_SG_H = sec_h;
    reg_RTC_SG_L = sec_l;
    reg_RTC_NS_H = ns_h;
    reg_RTC_NS_L = ns_l;

	reg_RTC_CTRL = RTC_SET_CTRL_0;
    reg_RTC_CTRL = RTC_SET_TIME; 
}


void ha_rtc_get_time(uint32_t *sec_h, uint32_t *sec_l, uint32_t *ns_h, uint32_t *ns_l) {
	reg_RTC_CTRL = RTC_SET_CTRL_0; 
	reg_RTC_CTRL = RTC_GET_TIME;

    // El mapa de memoria indica hacer polling hasta que el bit 0 sea 1 (DONE=1)
    while((reg_RTC_CTRL & RTC_GET_TIME) == 0x00);

    // Leer los registros 
    *sec_h = reg_RTC_SG_H;
    *sec_l = reg_RTC_SG_L;
    *ns_h  = reg_RTC_NS_H;
    *ns_l  = reg_RTC_NS_L;
}


void ha_rtc_adj_time(uint32_t adj_num, uint32_t adj_per_h, uint32_t adj_per_l) {
    reg_RTC_ADJNUM   = adj_num;
	reg_RTC_ADJPER_H = adj_per_h;
    reg_RTC_ADJPER_L = adj_per_l;

	reg_RTC_CTRL = RTC_SET_CTRL_0;
    reg_RTC_CTRL = RTC_SET_ADJ;

    while((reg_RTC_CTRL & RTC_SET_ADJ) == 0x00);
}


void ha_init_rtc(void) {  
	// cargamos periodo  
    ha_rtc_set_period(RTC_SET_PERIOD_H, RTC_SET_PERIOD_L);

	// reset
	reg_RTC_CTRL = RTC_SET_CTRL_0;
    reg_RTC_CTRL = RTC_SET_RESET;	
	
	// leemos RTC
	uint32_t s_h, s_l, n_h, n_l;
	ha_rtc_get_time(&s_h, &s_l, &n_h, &n_l);
    
    // Inicializar el reloj a 0
    ha_rtc_set_time(0, 0, 0, 0);
}


void ha_rtc_test_read_time(void){ 
	uint32_t s_h, s_l, n_h, n_l;
	print("--- Test de Lectura RTC ---\n");
    for (int i = 0; i < 5; i++) {
        ha_rtc_get_time(&s_h, &s_l, &n_h, &n_l);
        
        print("RTC -> Segundos: ");
        print_dec(s_l); 
        print(" | Nanosegundos: ");
        print_dec(n_h); 
        print("\n");
        
        // Un pequeño retardo artificial
        for(volatile int delay=0; delay<50; delay++);
    }
}

// ============================================================================
// FUNCIONES TSU (MARCAS DE TIEMPO)
// ============================================================================
void ha_init_tsu(void) {
	//Reset a las colas
	reg_TSU_RXCTRL = TSU_SET_CTRL_0;    
	reg_TSU_RXCTRL = TSU_SET_RST;
	delay(10);
	reg_TSU_RXCTRL = TSU_SET_CTRL_0; 

	reg_TSU_TXCTRL = TSU_SET_CTRL_0; 
	reg_TSU_TXCTRL = TSU_SET_RST;
	delay(10);
	reg_TSU_TXCTRL = TSU_SET_CTRL_0; 
	
	// Habilitamos la captura de todos los paquetes
	reg_TSU_RX_STATUS = TSU_MASK_MSGID;
	reg_TSU_TX_STATUS = TSU_MASK_MSGID;
		
}


void ha_check_rx_timestamp(uint8_t* rx_buffer, uint16_t rx_len, uint8_t *payload_vector) {
    uint32_t status;
	int queue_num = 0;
	int num_ptp = 0;

	status = reg_TSU_RX_STATUS;
	queue_num = status & 0xFF;

    if (queue_num > 0x0) {
        reg_TSU_RXCTRL = TSU_SET_CTRL_0;
		reg_TSU_RXCTRL = TSU_GET_QUE;	

		num_ptp = queue_num;

       	// Esperamos a que el registro se actualice
		do {
			status = reg_TSU_RXCTRL;

	  	}while((status & TSU_GET_QUE) == 0x00);

        // Leemos los segundos LL(15:0) y HL(31:0)
		uint32_t sec_ll = reg_TSU_RX_SG_HH & 0xFFFF;
        uint32_t sec_hl = reg_TSU_RX_SG_HL; 
        
        // Nanosegundos LH(29:0)
        uint32_t nsec = reg_TSU_RX_NS & 0x3FFFFFFF; 
        
        uint32_t info = reg_TSU_RX_INFO;
        uint16_t seq_id = info & 0xFFFF;                // Sequence ID (bits 15:0).
        uint8_t  msg_id = (info >> 28) & 0xF;           // Message ID (bits 31:28).

        // Guardamos el valor de TSU
		// 48 bits de SEGUNDOS
		payload_vector[0] = (sec_ll >> 8) & 0xFF;
		payload_vector[1] = (sec_ll)      & 0xFF;
		payload_vector[2] = (sec_hl >> 24) & 0xFF;
		payload_vector[3] = (sec_hl >> 16) & 0xFF;
		payload_vector[4] = (sec_hl >> 8)  & 0xFF;
		payload_vector[5] = (sec_hl)       & 0xFF;

		// 32 bits de NANOSEGUNDOS 
		payload_vector[6] = (nsec >> 24) & 0xFF;
		payload_vector[7] = (nsec >> 16) & 0xFF;
		payload_vector[8] = (nsec >> 8)  & 0xFF;
		payload_vector[9] = (nsec)       & 0xFF;

		// Guardamos en el array si hay espacio en la RAM
		if (ptp_rx_count >= MAX_PTP_RECORDS){
			ptp_rx_count = 0;
		}
		if (ptp_rx_count_generic >= MAX_PTP_RECORDS){
			ptp_rx_count_generic = 0;
		}

		if ((rx_buffer[22] != 0xFF)){
			// Buffer de guardado mensajes de sincronizacion
			if (ptp_rx_count < MAX_PTP_RECORDS) {
				// Guardar ID
				ptp_rx_history[ptp_rx_count].msg_id = msg_id;
				ptp_rx_history[ptp_rx_count].seq_id = seq_id;
				
				// Guardar Timestamping
				ptp_rx_history[ptp_rx_count].sec_ll = sec_ll;
				ptp_rx_history[ptp_rx_count].sec_hl = sec_hl;
				ptp_rx_history[ptp_rx_count].nsec   = nsec;

				// Calculamos y guardar Timestamping master
				ptp_time_t time_rx;

				time_rx.sec = sec_hl;
				time_rx.ns = nsec;

				ptp_time_t time_rx_master = ptp_sub_diff(time_rx, delay_ptp);

				ptp_rx_history[ptp_rx_count].sec_hl_master = time_rx_master.sec;
				ptp_rx_history[ptp_rx_count].nsec_master   = time_rx_master.ns;
				
				// Guardar el Mensaje
				ptp_rx_history[ptp_rx_count].packet_len = rx_len;
				uint16_t limit = (rx_len < SAVED_PAYLOAD_SIZE) ? rx_len : SAVED_PAYLOAD_SIZE;
				for(int i = 0; i < limit; i++) {
					ptp_rx_history[ptp_rx_count].payload[i] = rx_buffer[i];
				}
				
				ptp_rx_count++; 
			} 

		}else{
            // Buffer de guardado de mensaejes con ID FF
			if (ptp_rx_count_generic < MAX_PTP_RECORDS) {
				// Guardar ID
				ptp_rx_generic[ptp_rx_count_generic].msg_id = msg_id;
				ptp_rx_generic[ptp_rx_count_generic].seq_id = seq_id;
				
				// Guardar Timestamping
				ptp_rx_generic[ptp_rx_count_generic].sec_ll = sec_ll;
				ptp_rx_generic[ptp_rx_count_generic].sec_hl = sec_hl;
				ptp_rx_generic[ptp_rx_count_generic].nsec   = nsec;

				// Calculamos y guardar Timestamping master
				ptp_time_t time_rx;

				time_rx.sec = sec_hl;
				time_rx.ns = nsec;

				ptp_time_t time_rx_master = ptp_sub_diff(time_rx, delay_ptp);

				ptp_rx_generic[ptp_rx_count_generic].sec_hl_master = time_rx_master.sec;
				ptp_rx_generic[ptp_rx_count_generic].nsec_master   = time_rx_master.ns;
				
				// Guardar el Mensaje
				ptp_rx_generic[ptp_rx_count_generic].packet_len = rx_len;
				uint16_t limit = (rx_len < SAVED_PAYLOAD_SIZE) ? rx_len : SAVED_PAYLOAD_SIZE;
				for(int i = 0; i < limit; i++) {
					ptp_rx_generic[ptp_rx_count_generic].payload[i] = rx_buffer[i];
				}
				
				ptp_rx_count_generic++; 
			} 
		}        
    }
}


void ha_check_tx_timestamp(uint8_t *payload_vector, int disp) {
    uint32_t status;

	int queue_num = 0;
	int num_ptp = 0;

	status = reg_TSU_TX_STATUS;
	queue_num = status & 0xFF;

    while (queue_num > 0x0) {
        reg_TSU_TXCTRL = TSU_SET_CTRL_0;
		reg_TSU_TXCTRL = TSU_GET_QUE;
		num_ptp = queue_num;

       	// Esperamos a que el registro se actualice
		do {
			status = reg_TSU_TXCTRL;

	  	}while((status & TSU_GET_QUE) == 0x00);

        // Leemos los segundos LL(15:0) y HL(31:0)
		uint32_t sec_ll = reg_TSU_TX_SG_HH & 0xFFFF;
        uint32_t sec_hl = reg_TSU_TX_SG_HL; 
        
        // Nanosegundos LH(29:0)
        uint32_t nsec = reg_TSU_TX_NS & 0x3FFFFFFF; 
        
        uint32_t info = reg_TSU_TX_INFO;
        uint16_t seq_id = info & 0xFFFF;                // Sequence ID (bits 15:0).
        uint8_t  msg_id = (info >> 28) & 0xF;           // Message ID (bits 31:28).

		
		// 48 bits de SEGUNDOS
		payload_vector[0] = (sec_ll >> 8) & 0xFF;
		payload_vector[1] = (sec_ll)      & 0xFF;
		payload_vector[2] = (sec_hl >> 24) & 0xFF;
		payload_vector[3] = (sec_hl >> 16) & 0xFF;
		payload_vector[4] = (sec_hl >> 8)  & 0xFF;
		payload_vector[5] = (sec_hl)       & 0xFF;

		// 32 bits de NANOSEGUNDOS 
		payload_vector[6] = (nsec >> 24) & 0xFF;
		payload_vector[7] = (nsec >> 16) & 0xFF;
		payload_vector[8] = (nsec >> 8)  & 0xFF;
		payload_vector[9] = (nsec)       & 0xFF;
 		
		if (disp == 1){
			// Muestra de valores reales
			print("Num PTP: ");
			print_dec(num_ptp);
			print(" PTP TX [MsgID: ");
			print_dec(msg_id);
			print(" | SeqID: ");
			print_dec(seq_id);
			print("] -> Tiempo exacto: ");
			print_dec(sec_ll);
			print(" s(ll), ");
			print_dec(sec_hl);
			print(" s(hl), ");
			print_dec(nsec);
			print(" ns\n");


			// Muestra de valores crudos (hex)
			print("Valores hex: \n");
			print("s_ll: ");
			print_hex(payload_vector[0], 2);
			print(" ");
			print_hex(payload_vector[1], 2);

			print("\ns_hl: ");
			print_hex(payload_vector[2], 2);
			print(" ");
			print_hex(payload_vector[3], 2);
			print(" ");
			print_hex(payload_vector[4], 2);
			print_hex(payload_vector[5], 2);
			print(" ");

			print("\nnsec: ");
			print_hex(payload_vector[6], 2);
			print(" ");
			print_hex(payload_vector[7], 2);
			print(" ");
			print_hex(payload_vector[8], 2);
			print(" ");
			print_hex(payload_vector[9], 2);
			print("\n");
		}

		// Revisamos si quedan paquetes
		status = reg_TSU_TX_STATUS;
        queue_num = status & 0xFF;
    }
}



