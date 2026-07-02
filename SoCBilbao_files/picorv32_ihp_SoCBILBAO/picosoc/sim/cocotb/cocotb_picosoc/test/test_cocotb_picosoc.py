#!/usr/bin/env python3
# Copyright (c) 2026, Gonzalo De Pablo
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
import pytest
import os
from pathlib import Path
from cocotb.runner import get_runner



@pytest.mark.parametrize("seed", range(1))
@pytest.mark.parametrize(
    "sim_parameters", [
        {"frequency": "50000000"}
    ]
)
@pytest.mark.parametrize(
    "hdl_parameters", [
        {"DATA_WIDTH": "32"}
    ]
)
def test_cocotb_picosoc(seed, hdl_parameters, sim_parameters, request):
    """
    Test cocotb_picosoc using cocotb's runner API.
    This replaces the old cocotb-test approach.
    """
    # Get simulator from command line or environment
    sim = request.config.getoption("--sim") or os.environ.get("SIM", "questa")
    
    # Get project paths
    test_dir = Path(__file__).parent.resolve()
    proj_dir = test_dir.parent
    
    # Read source files and convert to absolute paths
    with open(proj_dir / "fileset.vhdl.txt", "r") as file:
        vhdl_sources = [str(proj_dir / line.strip()) for line in file if line.strip()]
    with open(proj_dir / "fileset.v.txt", "r") as file:
        verilog_sources = [str(proj_dir / line.strip()) for line in file if line.strip()]
    
    # Create runner
    runner = get_runner(sim)
    
    # Build simulation directory name
    sim_build_dir = proj_dir / "sim_build_test" / (
        str(seed) + "_" + 
        "_".join(("{}__{}".format(*i) for i in hdl_parameters.items())) + "_" + 
        "_".join(("{}__{}".format(*i) for i in sim_parameters.items()))
    )
    

    proj_dir = Path(__file__).parent.parent.resolve()
    firmware_path = proj_dir / "top/fw_sim.hex"
    
    # Build the simulation
    runner.build(
    sources=verilog_sources,   # solo verilog, lista unificada
    hdl_toplevel="cocotb_picosoc",
    build_dir=sim_build_dir,
    parameters=hdl_parameters,
    build_args=[],
)
    
    # Set up environment variables for the test
    env = os.environ.copy()
    for key, value in sim_parameters.items():
        env[key] = str(value)
    env['COCOTB_TEST_SEED'] = str(seed)
    env['COCOTB_LOG_LEVEL'] = 'INFO'
    env['COCOTB_RESOLVE_X'] = 'ZEROS'
    
    for var in ['PATH', 'LD_LIBRARY_PATH']:
        if var in env:
            env[var] = ':'.join(p for p in env[var].split(':') if 'CALIBRE' not in p and 'calibre' not in p)

    # Run the test
    runner.test(
        hdl_toplevel="cocotb_picosoc",
        test_module="cocotb_picosoc",
        build_dir=sim_build_dir,
        test_args=[f"+firmware={firmware_path}"],
        extra_env=env,
    )


if __name__ == "__main__":
    pytest.main([__file__])
