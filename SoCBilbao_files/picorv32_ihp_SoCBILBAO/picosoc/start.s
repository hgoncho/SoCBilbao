.section .text
.global irq

# ----------------------------------------------------------------
# 1. VECTOR DE ENTRADA (Dirección 0x00000000)
# ----------------------------------------------------------------
start:
    /* El procesador salta a 0x0 en Reset y a 0x10 en Interrupción.
       Ajustamos el flujo con saltos relativos. */
    j real_start            # Reset: Salta a inicialización (0x0)
    
    .balign 16              # Forzamos que la siguiente instrucción esté en 0x10
interrupt_handler:          # Trap: Punto de entrada de la interrupción
    j trap_entry            # Salta al gestor de contexto


# ----------------------------------------------------------------
# 2. INICIALIZACIÓN DEL SISTEMA (código original)
# ----------------------------------------------------------------
real_start:
# zero-initialize register file
addi x1, zero, 0
# x2 (sp) is initialized by reset
addi x3, zero, 0
addi x4, zero, 0
addi x5, zero, 0
addi x6, zero, 0
addi x7, zero, 0
addi x8, zero, 0
addi x9, zero, 0
addi x10, zero, 0
addi x11, zero, 0
addi x12, zero, 0
addi x13, zero, 0
addi x14, zero, 0
addi x15, zero, 0
addi x16, zero, 0
addi x17, zero, 0
addi x18, zero, 0
addi x19, zero, 0
addi x20, zero, 0
addi x21, zero, 0
addi x22, zero, 0
addi x23, zero, 0
addi x24, zero, 0
addi x25, zero, 0
addi x26, zero, 0
addi x27, zero, 0
addi x28, zero, 0
addi x29, zero, 0
addi x30, zero, 0
addi x31, zero, 0

# Update LEDs
li a0, 0x03000000
li a1, 1
sw a1, 0(a0)

# zero initialize entire scratchpad memory
li a0, 0x00000000
setmemloop:
sw a0, 0(a0)
addi a0, a0, 4
blt a0, sp, setmemloop

# Update LEDs
li a0, 0x03000000
li a1, 3
sw a1, 0(a0)

# copy data section
la a0, _sidata
la a1, _sdata
la a2, _edata
bge a1, a2, end_init_data
loop_init_data:
lw a3, 0(a0)
sw a3, 0(a1)
addi a0, a0, 4
addi a1, a1, 4
blt a1, a2, loop_init_data
end_init_data:

# Update LEDs
li a0, 0x03000000
li a1, 7
sw a1, 0(a0)

# zero-init bss section
la a0, _sbss
la a1, _ebss
bge a0, a1, end_init_bss
loop_init_bss:
sw zero, 0(a0)
addi a0, a0, 4
blt a0, a1, loop_init_bss
end_init_bss:

# Update LEDs
li a0, 0x03000000
li a1, 15
sw a1, 0(a0)

# call main
call main
loop:
j loop

# ----------------------------------------------------------------
# 3. GESTOR DE TRAPS (Salvaguarda de registros)
# ----------------------------------------------------------------
trap_entry:
    /* Al entrar aquí, el PicoRV32 ha guardado:
       - q0: Dirección de retorno
       - q1: Máscara de IRQs activas */

    # Reservar espacio en la pila para registros (Context Saving)
    addi sp, sp, -64
    sw x1,  0(sp)   # ra
    sw x5,  4(sp)   # t0
    sw x6,  8(sp)   # t1
    sw x7,  12(sp)  # t2
    sw x10, 16(sp)  # a0
    sw x11, 20(sp)  # a1
    sw x12, 24(sp)  # a2
    sw x13, 28(sp)  # a3
    sw x14, 32(sp)  # a4
    sw x15, 36(sp)  # a5
    sw x16, 40(sp)  # a6
    sw x17, 44(sp)  # a7
    sw x28, 48(sp)  # t3
    sw x29, 52(sp)  # t4
    sw x30, 56(sp)  # t5
    sw x31, 60(sp)  # t6

    # Preparar argumentos para la función C: irq(uint32_t *regs, uint32_t irqs)
    mv a0, sp                       # Argumento 1: Puntero a registros guardados    
    .word 0x0010458B
    call irq                        # Saltar a tu función en firmware.c

    # Restaurar registros (Context Restore)
    lw x1,  0(sp)
    lw x5,  4(sp)
    lw x6,  8(sp)
    lw x7,  12(sp)
    lw x10, 16(sp)
    lw x11, 20(sp)
    lw x12, 24(sp)
    lw x13, 28(sp)
    lw x14, 32(sp)
    lw x15, 36(sp)
    lw x16, 40(sp)
    lw x17, 44(sp)
    lw x28, 48(sp)
    lw x29, 52(sp)
    lw x30, 56(sp)
    lw x31, 60(sp)
    addi sp, sp, 64

    # Retornar de la interrupción
    .word 0x0400000b                # ESTO ES RETIRQ (Correcto: 0x04...)



.global flashio_worker_begin
.global flashio_worker_end

.balign 4

flashio_worker_begin:
# a0 ... data pointer
# a1 ... data length
# a2 ... optional WREN cmd (0 = disable)

# address of SPI ctrl reg
li   t0, 0x02000000

# Set CS high, IO0 is output
li   t1, 0x120
sh   t1, 0(t0)

# Enable Manual SPI Ctrl
sb   zero, 3(t0)

# Send optional WREN cmd
beqz a2, flashio_worker_L1
li   t5, 8
andi t2, a2, 0xff
flashio_worker_L4:
srli t4, t2, 7
sb   t4, 0(t0)
ori  t4, t4, 0x10
sb   t4, 0(t0)
slli t2, t2, 1
andi t2, t2, 0xff
addi t5, t5, -1
bnez t5, flashio_worker_L4
sb   t1, 0(t0)

# SPI transfer
flashio_worker_L1:
beqz a1, flashio_worker_L3
li   t5, 8
lbu  t2, 0(a0)
flashio_worker_L2:
srli t4, t2, 7
sb   t4, 0(t0)
ori  t4, t4, 0x10
sb   t4, 0(t0)
lbu  t4, 0(t0)
andi t4, t4, 2
srli t4, t4, 1
slli t2, t2, 1
or   t2, t2, t4
andi t2, t2, 0xff
addi t5, t5, -1
bnez t5, flashio_worker_L2
sb   t2, 0(a0)
addi a0, a0, 1
addi a1, a1, -1
j    flashio_worker_L1
flashio_worker_L3:

# Back to MEMIO mode
li   t1, 0x80
sb   t1, 3(t0)

ret

.balign 4
flashio_worker_end:
