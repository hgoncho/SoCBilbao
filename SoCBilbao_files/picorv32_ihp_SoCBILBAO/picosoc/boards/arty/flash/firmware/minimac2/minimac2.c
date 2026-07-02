#include "minimac2.h"

// --- REGISTROS HARDWARE MINIMAC2 ---
#define reg_irq_status (*(volatile uint32_t*)0x02000010)
#define reg_irq_mask   (*(volatile uint32_t*)0x02000014)

#define reg_PHY_RST   (*(volatile uint32_t*)0x02000020)
#define reg_MII_MGMT  (*(volatile uint32_t*)0x02000024)
#define reg_SLOT0_CTL (*(volatile uint32_t*)0x02000028)
#define reg_RX_COUNT0 (*(volatile uint32_t*)0x0200002C)
#define reg_SLOT1_CTL (*(volatile uint32_t*)0x02000030)
#define reg_RX_COUNT1 (*(volatile uint32_t*)0x02000034)
#define reg_TX_COUNT  (*(volatile uint32_t*)0x02000038)

#define MINIMAC_MEM_BASE (*(volatile uint32_t*)0x04000000)
#define ETH_RX0_BUF      ((volatile uint32_t*)0x04000000)
#define ETH_RX1_BUF      ((volatile uint32_t*)0x04000800)
#define ETH_TX_BUF       ((volatile uint32_t*)0x04001000)

// Estados de los buffers RX
#define RX_STATE_EMPTY   0
#define RX_STATE_READY   1
#define RX_STATE_PENDING 2

// --- VARIABLES GLOBALES  ---
volatile int RX_active = 0;
volatile int TX_active = 0;
uint8_t custom_tx_buffer[MAX_ETH_FRAME];

const uint8_t MI_MAC_ORIGEN[6] = {0x02, 0x00, 0x00, 0x00, 0x00, 0x01};
const uint8_t mac_all[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};


void minimac2_init()
{
	// Reset del core minimac2
	reg_PHY_RST = 0x01;
	reg_PHY_RST = 0x00;
	
	reg_SLOT0_CTL = RX_STATE_READY;
	reg_SLOT1_CTL = RX_STATE_READY;
}


void minimac2_init_interrupts(void) {
    reg_irq_status = irq_bit_minimac2_tx | irq_bit_minimac2_rx;
    reg_irq_mask   = irq_bit_minimac2_tx | irq_bit_minimac2_rx; 
}


void minimac2_send(uint8_t*data, uint16_t len)
{	
	volatile uint8_t *tx_byte_ptr = (volatile uint8_t *)ETH_TX_BUF;  

	for (int i = 0; i < len; i++) {
    	tx_byte_ptr[i] = data[i];
	}
	reg_TX_COUNT = len;
		
}


uint16_t minimac2_process_rx(uint8_t *dest_buffer) {
    uint32_t len = 0;

    // --- Revisar Slot 0 ---
    if (reg_SLOT0_CTL == RX_STATE_PENDING) {	
		len = (reg_RX_COUNT0 > MAX_BUFFER) ? MAX_BUFFER : reg_RX_COUNT0;

		volatile uint8_t *rx_byte_ptr = (volatile uint8_t *)ETH_RX0_BUF;			

        for (int i = 0; i < len; i++) {
            dest_buffer[i] = rx_byte_ptr[i];
        }
        reg_SLOT0_CTL = RX_STATE_READY;
	
		reg_irq_status = irq_bit_minimac2_rx;
		reg_irq_mask |= irq_bit_minimac2_rx;

        return len;
    }
    // --- Revisar Slot 1  ---
    if (reg_SLOT1_CTL == RX_STATE_PENDING) {
		len = (reg_RX_COUNT1 > MAX_BUFFER) ? MAX_BUFFER : reg_RX_COUNT1;	
		
		volatile uint8_t *rx_byte_ptr = (volatile uint8_t *)ETH_RX1_BUF;
        for (int i = 0; i < len; i++) {
            dest_buffer[i] = rx_byte_ptr[i];
        }
	
        reg_SLOT1_CTL = RX_STATE_READY;
	
		reg_irq_status = irq_bit_minimac2_rx;
		reg_irq_mask |= irq_bit_minimac2_rx;

        return len;
    }

    //Volvemos a escuchar interrupciones 
    reg_irq_status = irq_bit_minimac2_rx;
    reg_irq_mask |= irq_bit_minimac2_rx;

    return 0; // No hay paquetes
}


uint16_t gen_trama (const uint8_t *mac_dest, uint16_t ethertype, const uint8_t *payload, uint16_t payload_len) {
    uint16_t total_len = 0;

    // 0. PREÁMBULO Y SFD (8 bytes)
    for (int i = 0; i < 7; i++) {
        custom_tx_buffer[total_len++] = 0x55;
    }
    custom_tx_buffer[total_len++] = 0xD5;

    // 1. MAC Destino (6 bytes)
    for (int i = 0; i < 6; i++) {
        custom_tx_buffer[total_len++] = mac_dest[i];
    }

    // 2. MAC Origen (6 bytes)
    for (int i = 0; i < 6; i++) {
        custom_tx_buffer[total_len++] = MI_MAC_ORIGEN[i];
    }

    // 3. EtherType (2 bytes)
    custom_tx_buffer[total_len++] = (ethertype >> 8) & 0xFF;
    custom_tx_buffer[total_len++] = ethertype & 0xFF;

    // 4. Payload 
    if (payload_len > (MAX_ETH_FRAME - 22)) {
        payload_len = MAX_ETH_FRAME - 22; 
    }
    for (int i = 0; i < payload_len; i++) {
        custom_tx_buffer[total_len++] = payload[i];
    }

    // (Preámbulo) + 60 (Mínimo Ethernet sin CRC) = 68 bytes mínimos
    while (total_len < 68) {
        custom_tx_buffer[total_len++] = 0x00;
    }

	return total_len;

};
