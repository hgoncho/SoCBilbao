#ifndef SPIFLASH_H
#define SPIFLASH_H

#include <stdint.h>

// Firmas de las funciones de configuración Flash
void set_flash_qspi_flag(void);
void set_flash_mode_spi(void);
void set_flash_mode_dual(void);
void set_flash_mode_quad(void);
void set_flash_mode_qddr(void);
void enable_flash_crm(void);

#endif // SPIFLASH_H