#ifndef SIMPLEUART_H
#define SIMPLEUART_H

#include <stdint.h>

void inituart(void);

// --- Funciones de transmisión ---
void putchar(char c);
void print(const char *p);
void print_hex(uint32_t v, int digits);
void print_dec(uint32_t v);

// --- Funciones de recepción ---
int32_t read_log(void);
char getchar_prompt(char *prompt);
char getchar(void);

// --- Funciones imprimit PTP ---
void print_saved_message (uint32_t i);
void print_saved_index_ptp(void);
void print_ptp_time(ptp_time_t t);


#endif // SIMPLEUART_H