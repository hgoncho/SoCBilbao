#ifndef MINIMAC2_H
#define MINIMAC2_H

#include <stdint.h>

// --- Macros y Constantes Públicas ---
#define MAX_BUFFER      128
#define MAX_ETH_FRAME   90

// --- Variables compartidas  ---
extern volatile int RX_active;
extern volatile int TX_active;

// Mascaras de irq
#define irq_bit_minimac2_tx  (1<<5)   // 0x0000_0020
#define irq_bit_minimac2_rx  (1<<6)   // 0x0000_0040

// --- Buffers y MACs Públicos ---
extern uint8_t custom_tx_buffer[MAX_ETH_FRAME];
extern const uint8_t mac_all[6];
extern const uint8_t MI_MAC_ORIGEN[6];



/**
 * @brief Inicia y activa el core minimac2
 * 
 */
void minimac2_init(void);


/**
 * @brief Inicia y activa las interrupciones del minimac2
 * 
 */
void minimac2_init_interrupts(void);


/**
 * @brief Envia una cadena de caracteres de longitud variable
 * 
 * @param data Cadena de caracteres de envio
 * @param len Longitud de la cadena de envio
 */
void minimac2_send(uint8_t *data, uint16_t len);


/**
 * @brief Lee los buffers de hardware para comprobar si ha llegado un nuevo paquete.
 * 
 * @param dest_buffer Puntero al array de RAM donde se copiará el paquete recibido.
 * @return La longitud del paquete recibido en bytes. Retorna 0 si no hay paquetes nuevos. 
 */
uint16_t minimac2_process_rx(uint8_t *dest_buffer);


/**
 * @brief Ensambla una trama Ethernet completa en el buffer de transmisión.
 * 
 * @param mac_dest Array de 6 bytes con la dirección MAC de destino.
 * @param ethertype Código de 16 bits del protocolo (0x88F7 para PTP).
 * @param payload Puntero al array de datos que queremos enviar.
 * @param payload_len Longitud en bytes de los datos
 * @return  La longitud total en bytes de la trama generada, lista para ser enviada.
 */
uint16_t gen_trama(const uint8_t *mac_dest, uint16_t ethertype, const uint8_t *payload, uint16_t payload_len);


#endif // MINIMAC2_H