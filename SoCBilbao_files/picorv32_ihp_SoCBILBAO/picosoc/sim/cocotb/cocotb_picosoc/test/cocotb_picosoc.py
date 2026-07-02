#!/usr/bin/env python3
# Copyright (c) 2026, Gonzalo De Pablo
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

"""
Cocotb testbench for cocotb_picosoc.

Testbench completo para el SoCBilbao con minimac2 y ha1588.
Incluye monitor UART con eventos de sincronización, inyección de
tramas Ethernet desde fichero .pcap y construcción manual de
paquetes PTP IEEE 1588.

Referencias:
  - cocotb:           https://docs.cocotb.org/en/stable/
  - cocotbext-uart:   https://github.com/alexforencich/cocotbext-uart
  - cocotbext-eth:    https://github.com/alexforencich/cocotbext-eth
  - scapy:            https://scapy.readthedocs.io/
"""

import os
import cocotb
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, Event
from cocotbext.uart import UartSource, UartSink
from cocotbext.eth import MiiSource, MiiSink, GmiiFrame, MiiPhy

import logging
logging.getLogger("cocotb").setLevel(logging.DEBUG)
logging.getLogger("cocotb.cocotb_picosoc.uart_0_tx").setLevel(logging.WARNING)
logging.getLogger("cocotb.cocotb_picosoc.uart_0_rx").setLevel(logging.WARNING)
logging.getLogger("cocotb.cocotb_picosoc.mii_0_rxd").setLevel(logging.WARNING)
logging.getLogger("cocotb.cocotb_picosoc.mii_0_txd").setLevel(logging.WARNING)


from scapy.all import rdpcap, raw


class TB:
    """Testbench para cocotb_picosoc (SoCBilbao + minimac2 + ha1588).

    Gestiona relojes, reset, monitor UART con sincronización por eventos
    e interfaces MII para inyección/captura de tramas Ethernet.
    """

    def __init__(self, dut):
        """Inicializa el testbench y configura todos los drivers de interfaz.

        Args:
            dut: Handle del dispositivo bajo test proporcionado por cocotb.
        """
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        # Reset activo bajo — se mantiene asertado hasta llamar a initialize()
        self.dut.rst_n.value = 0

        # -----------------------------------------------------------
        # UART  —  115200 bps
        # -----------------------------------------------------------
        self.uart_source_0 = UartSource(dut.uart_0_rx, baud=115200)
        self.uart_sink_0   = UartSink(dut.uart_0_tx,   baud=115200)
        self.uart_sync_msg = ""       # Mensaje que dispara el evento
        self.uart_event    = Event()  # Semáforo de sincronización

        # -----------------------------------------------------------
        # MII  —  reset_active_level=False porque rst_n es activo bajo
        # -----------------------------------------------------------
        # self.mii_phy_0 = MiiPhy(
        #     dut.mii_0_rxd, dut.mii_0_rx_er, dut.mii_0_rx_dv, dut.mii_0_rx_clk,
        #     dut.mii_0_txd, dut.mii_0_tx_er, dut.mii_0_tx_en, dut.mii_0_tx_clk,
        # )
        self.mii_source_0 = MiiSource(
            dut.mii_0_rxd, dut.mii_0_rx_er, dut.mii_0_rx_dv, dut.mii_0_rx_clk,
        )
        # self.mii_sink_0 = MiiSink(
        #     dut.mii_0_txd, dut.mii_0_tx_er, dut.mii_0_tx_en, dut.mii_0_tx_clk,
        # )

        # Arrancamos el monitor UART en background
        self.uart_monitor_active = True
        cocotb.start_soon(self.uart_monitor())



    # ------------------------------------------------------------------
    # GENERACIÓN DE RELOJES
    # ------------------------------------------------------------------
    async def clock_gen(self):
        """Arranca los relojes del sistema y del PHY MII.

        El reloj del sistema se deriva de la variable de entorno 'frequency'
        (en Hz) que inyecta el runner de pytest. Los relojes MII se fijan
        a 25 MHz (MII 100 Mbps).
        """
        freq_hz = int(os.environ.get("frequency", "50000000"))
        period_ps = int(1E12 / freq_hz)

        # Reloj del sistema
        cocotb.start_soon(Clock(self.dut.clk, period_ps, units="ps").start())

        # Relojes PHY MII: 25 MHz → 40 ns
        cocotb.start_soon(Clock(self.dut.mii_0_rx_clk, 40, units="ns").start())
        cocotb.start_soon(Clock(self.dut.mii_0_tx_clk, 40, units="ns").start())


    # ------------------------------------------------------------------
    # RESET
    # ------------------------------------------------------------------
    async def initialize(self):
        """Aplica la secuencia de reset y espera a que el DUT esté listo.

        Mantiene rst_n=0 durante 100 ciclos de reloj del sistema y luego
        lo libera.
        """
        self.log.info("TestBench -> Iniciando secuencia de reset")
        self.dut.rst_n.value = 0

        for _ in range(100):
            await RisingEdge(self.dut.clk)

        self.dut.rst_n.value = 1
        self.log.info("TestBench -> Reset liberado")
        

    # ------------------------------------------------------------------
    # MONITOR UART  (corre en background durante toda la simulación)
    # ------------------------------------------------------------------
    async def uart_monitor(self):
        """Lee continuamente la UART TX del SoC y vuelca cada línea al log.

        Detecta caracteres basura (bytes no ASCII imprimibles) y dispara
        el evento de sincronización cuando la línea recibida contiene el
        mensaje registrado en uart_sync_msg.
        """
        buffer = ""
        while True:
            if not self.uart_monitor_active:
                await Timer(100, units="us")
                continue
            data = await self.uart_sink_0.read(1)
            char = data[0]

            if char in (0x0A, 0x0D):           # LF o CR → fin de línea
                if buffer:
                    self.log.info(f"[UART RX] {buffer}")
                    if self.uart_sync_msg and self.uart_sync_msg in buffer:
                        self.uart_event.set()
                    buffer = ""

            elif 32 <= char < 127:              # ASCII imprimible
                buffer += chr(char)
                #self.log.debug(f"[UART RX - BYTE] '{chr(char)}' (0x{char:02X})")

         #   else:
               # self.log.warning(f"[UART RX - BASURA] Byte raro: 0x{char:02X}")
                # Añade esto para ver también los bytes en el buffer:
                #self.log.debug(f"[UART RX - BUFFER actual] '{buffer}'")



    # ------------------------------------------------------------------
    # ESPERA SINCRONIZADA A MENSAJE UART
    # ------------------------------------------------------------------
    async def wait_for_uart_msg(self, msg):
        """Bloquea la corrutina llamante hasta recibir 'msg' por UART.

        Args:
            msg: Cadena que debe aparecer en una línea de la UART TX del SoC.
        """
        self.uart_sync_msg = msg
        self.uart_event.clear()
        await self.uart_event.wait()
        self.uart_sync_msg = ""


# ----------------------------------------------------------------------
# UTILIDADES DE PCAP
# ----------------------------------------------------------------------
def cargar_tramas_pcap(ruta_pcap):
    """Lee un fichero .pcap y devuelve una lista de tramas como bytes puros.

    Args:
        ruta_pcap: Ruta al fichero .pcap (absoluta o relativa).

    Returns:
        Lista de bytes, una entrada por trama.
    """
    paquetes = rdpcap(str(ruta_pcap))
    return [raw(pkt) for pkt in paquetes]


# ----------------------------------------------------------------------
# CONSTRUCTOR DE PAQUETES PTP IEEE 1588
# ----------------------------------------------------------------------
def build_ptp_packet():
    """Construye un paquete PTP Sync sobre Ethernet (sin preámbulo ni CRC).

    cocotbext-eth añade preámbulo, SFD y CRC automáticamente al enviar.

    Returns:
        bytes con la trama Ethernet completa (MAC + EtherType + payload PTP).
    """
    mac_dest  = b'\xFF\xFF\xFF\xFF\xFF\xFF'
    mac_src   = b'\x02\x00\x00\x00\x00\x01'
    ethertype = b'\x88\xF7'                 # EtherType PTP

    ptp_header = (
        b'\x00\x02'   +   # messageType + versionPTP
        b'\x00\x2C'   +   # messageLength (44 bytes)
        b'\x00\x00'   +   # domainNumber + reserved
        b'\x02\x00'   +   # flags
        b'\x00' * 8   +   # correctionField
        b'\x00' * 4   +   # reserved
        b'\x00' * 8   +   # sourcePortIdentity (clockIdentity)
        b'\x00\x01'   +   # sourcePortIdentity (portNumber)
        b'\x00\x2A'   +   # sequenceId = 42
        b'\x00\x00'       # controlField + logMessageInterval
    )

    ptp_payload = b'\x00' * 10   # originTimestamp
    padding     = b'\x00' * 2    # relleno hasta mínimo Ethernet

    return mac_dest + mac_src + ethertype + ptp_header + ptp_payload + padding


# ----------------------------------------------------------------------
# SECUENCIA DE SIMULACIÓN PRINCIPAL
# ----------------------------------------------------------------------
@cocotb.test(timeout_time=500, timeout_unit="ms")
async def t_cocotb_picosoc(dut):
    """Test principal del SoCBilbao.

    Secuencia completa:
      1. Arranque de relojes y reset.
      2. Espera al bootloader y pulsación de ENTER.
      3. Envío del comando 'S' para que el SoC transmita un paquete TX.
      4. Captura e inspección del paquete TX por el PHY.
      5. Carga de tramas desde fichero .pcap e inyección por el PHY RX.
      6. Comandos de inspección 'I' y 'P' por UART.

    Args:
        dut: Handle del dispositivo bajo test proporcionado por cocotb.
    """

    # ------------------------------------------------------------------
    # 1. ARRANQUE
    # ------------------------------------------------------------------
    # Reset temprano antes de crear el TB (igual que el boilerplate)
    dut.rst_n.value = 0
    dut.clk.value   = 0
    await Timer(10, units="ns")

    tb = TB(dut)
    await tb.clock_gen()
    await tb.initialize()

    # tb.log.info("Monitorizando señales toplevel...")
    # for i in range(50):
    #     await Timer(1, units="ms")
    #     tb.log.info(f"[t={i+1}ms] uart_tx={dut.uart_0_tx.value} rst_n={dut.rst_n.value} flash_csb={dut.flash_csb.value} flash_clk={dut.flash_clk.value}")

    # for i in range(10):
    #     await Timer(1, units="ms")
    #     tb.log.info(f"[t={i+1}ms] uart_tx={dut.uart_0_tx.value} flash_csb={dut.flash_csb_mon.value}")


    # tb.log.info("TestBench -> Monitorizando señal raw uart_0_tx...")
    # for i in range(20):
    #     await Timer(1, units="ms")
    #     tb.log.info(f"[RAW] uart_0_tx = {dut.uart_0_tx.value} | rst_n = {dut.rst_n.value}")

    await Timer(5, units="ms")   # dar tiempo a que la CPU lea la flash y arranque
    tb.log.info("TestBench -> CPU arrancada. Esperando mensaje del bootloader...")



    # ------------------------------------------------------------------
    # 2. BOOTLOADER
    # ------------------------------------------------------------------
    await tb.wait_for_uart_msg("Press ENTER to continue")
    tb.log.info("TestBench -> Enviando ENTER (0x0D)")
    await tb.uart_source_0.write(b'\x0D')
    await tb.uart_source_0.wait()


    # ------------------------------------------------------------------
    # 3. COMANDO S — el SoC envía un paquete Ethernet
    # ------------------------------------------------------------------
    await tb.wait_for_uart_msg("Esperando comando.")
    tb.log.info("TestBench -> Enviando comando 'S'")
    await tb.uart_source_0.write(b'S')


    # ------------------------------------------------------------------
    # 4. CAPTURA DEL PAQUETE TX
    # ------------------------------------------------------------------
    tb.log.info("TestBench -> Esperando paquete TX del PHY...")
    
    # Crear MiiSink solo cuando lo necesitamos
    mii_sink = MiiSink(
        dut.mii_0_txd, dut.mii_0_tx_er, dut.mii_0_tx_en, dut.mii_0_tx_clk,
    )
    tx_frame = await mii_sink.recv()
    tx_bytes = bytes(tx_frame)
    hex_data = " ".join(f"{b:02X}" for b in tx_bytes)
    tb.log.info(f"TestBench -> Paquete TX capturado — {len(tx_bytes)} bytes")
    tb.log.info(f"TestBench -> Datos TX: {hex_data}")
    
    # Destruir el sink para que deje de monitorizar
    del mii_sink
    await Timer(1, units="us")


    # ------------------------------------------------------------------
    # 5. CARGA E INYECCIÓN DE TRAMAS PCAP
    # ------------------------------------------------------------------
    # Ruta relativa al directorio del test para portabilidad
    test_dir     = Path(__file__).parent
    ruta_archivo = test_dir / "pcap" / "ptpv2.pcap"

    lista_tramas = cargar_tramas_pcap(ruta_archivo)
    tb.log.info(f"TestBench -> {len(lista_tramas)} tramas cargadas desde {ruta_archivo.name}")

    frame = GmiiFrame.from_payload(lista_tramas[0])
    tb.log.info("TestBench -> Inyectando paquete 1 en el PHY RX...")
    await tb.mii_source_0.send(frame)
    await tb.mii_source_0.wait()

    frame = GmiiFrame.from_payload(lista_tramas[1])
    tb.log.info("TestBench -> Inyectando paquete 2 en el PHY RX...")
    await tb.mii_source_0.send(frame)
    await tb.mii_source_0.wait()


    # ------------------------------------------------------------------
    # 6. COMANDO I — resumen de paquetes RX recibidos
    # ------------------------------------------------------------------
    tb.uart_monitor_active = False
    await Timer(1, units="us")
    tb.log.info("TestBench -> Enviando comando 'I'")
    await tb.uart_source_0.write(b'I')
    await Timer(50, units="ms")
    tb.uart_monitor_active = True
    await Timer(250, units="us")


    # ------------------------------------------------------------------
    # 7. COMANDO P — mostrar paquete 1
    # ------------------------------------------------------------------
    tb.log.info("TestBench -> Enviando comando 'P'")
    await tb.uart_source_0.write(b'P')
    await tb.wait_for_uart_msg("Introduce un numero valido")
    tb.uart_monitor_active = False
    tb.log.info("TestBench -> Seleccionando paquete 1")
    await tb.uart_source_0.write(b'1')
    await Timer(45, units="ms")
    tb.uart_monitor_active = True
    await Timer(250, units="us")




    # ------------------------------------------------------------------
    # 8. COMANDO P — mostrar paquete 2
    # ------------------------------------------------------------------
    tb.log.info("TestBench -> Enviando comando 'P'")
    await tb.uart_source_0.write(b'P')
    await tb.wait_for_uart_msg("Introduce un numero valido")
    tb.uart_monitor_active = False
    tb.log.info("TestBench -> Seleccionando paquete 2")
    await tb.uart_source_0.write(b'2')
    await Timer(45, units="ms")

    #await tb.wait_for_uart_msg("Esperando comando.")

    tb.log.info("TestBench -> Simulación completada correctamente.")