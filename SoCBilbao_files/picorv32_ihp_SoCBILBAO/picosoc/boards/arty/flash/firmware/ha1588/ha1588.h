#ifndef HA1588_H
#define HA1588_H

#include <stdint.h>

// --- Macros  ---
#define MAX_PTP_RECORDS 3        
#define SAVED_PAYLOAD_SIZE 80

// --- Estructuras de Datos ---
// Estructura de tiempos
typedef struct { 
	int32_t sec; 
	int32_t ns; 
} ptp_time_t;

// Estructura de guardado de tramas
typedef struct {
    uint8_t  msg_id;
    uint16_t seq_id;
    
    uint32_t sec_ll;
    uint32_t sec_hl;
    uint32_t nsec;

    uint32_t sec_ll_master;
    uint32_t sec_hl_master;
    uint32_t nsec_master;
    
    uint16_t packet_len;                 
    uint8_t  payload[SAVED_PAYLOAD_SIZE];
} ptp_record_t;

// --- Variables Globales (Historiales y Tiempos) ---
extern ptp_record_t ptp_rx_history[MAX_PTP_RECORDS];
extern ptp_record_t ptp_rx_generic[MAX_PTP_RECORDS];

extern uint32_t ptp_rx_count;
extern uint32_t ptp_rx_count_generic;

extern ptp_time_t delay_ptp;
extern ptp_time_t offset;

// --- Funciones RTC/TSU ---
void delay(int delay);
void ha_init_rtc(void);
void ha_init_tsu(void);

void ha_rtc_set_period(uint32_t per_h, uint32_t per_l);
void ha_rtc_set_time(uint32_t sec_h, uint32_t sec_l, uint32_t ns_h, uint32_t ns_l);
void ha_rtc_get_time(uint32_t *sec_h, uint32_t *sec_l, uint32_t *ns_h, uint32_t *ns_l);
void ha_rtc_adj_time(uint32_t adj_num, uint32_t adj_per_h, uint32_t adj_per_l);
void ha_rtc_test_read_time(void);

void ha_check_rx_timestamp(uint8_t* rx_buffer, uint16_t rx_len, uint8_t *payload_vector);
void ha_check_tx_timestamp(uint8_t *payload_vector, int disp);

// --- Funciones de Matemáticas PTP y Debug ---
ptp_time_t extraer_tiempo(uint8_t *vector);
ptp_time_t ptp_sub_diff(ptp_time_t a, ptp_time_t b);
ptp_time_t ptp_add_diff(ptp_time_t a, ptp_time_t b);
ptp_time_t ptp_div2(ptp_time_t a);
void print_ptp_time(ptp_time_t t);
void print_saved_index_ptp(void);
void print_saved_message(uint32_t i);

#endif // HA1588_H