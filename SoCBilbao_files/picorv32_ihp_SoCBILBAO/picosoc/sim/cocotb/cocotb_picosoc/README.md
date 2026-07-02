---
title: cocotb_picosoc
author: Gonzalo De Pablo
date: 2026-05-25
---

## Description

cocotb testbench for picosoc

## Directory structure

- [top](./top): Top HDL files for simulation.
- [test](./test): `pytest` configuration Python modules and testbenches using `cocotb`.
- [formal](./formal): Formal verification properties.

## Makefile

The Makefile contains several targets to ease the simulation and formal verification process.

- `make test`: Run the simulation.
- `make test_view`: Run the simulation with trace output.
- `make formal`: Run the formal verification.
- `make clean`: Clean the simulation and formal verification files.
- `make help`: Show the available targets.

## Information

- [Cocotb documentation](https://docs.cocotb.org/en/stable/index.html).
- [Cocotb AXI simulation](https://github.com/alexforencich/cocotbext-axi/).
- When simulating Xilinx systems do not forget to:
  - Add glbl.v(hdl)
  - Add the Xilinx library to the simulator:
    - questa: `sim_args = ["-L","unisims_ver","-L","unimacro_ver","-L","unisim", "-L","unimacro","-L","secureip", "-Ldir","/opt/questa_lib","test_questa.glbl"]`
    - VCS: TBD
- [Formal testing with sby](https://yosyshq.readthedocs.io/projects/sby/en/latest/)

## Interfaces

- UART: 1 — [cocotbext-uart](https://github.com/alexforencich/cocotbext-uart)
- MII Ethernet: 1 — [cocotbext-eth](https://github.com/alexforencich/cocotbext-eth)

## Version history

- 0.1.0: Initial version
