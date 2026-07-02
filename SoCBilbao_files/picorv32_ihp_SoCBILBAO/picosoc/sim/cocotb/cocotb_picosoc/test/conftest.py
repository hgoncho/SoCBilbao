#!/usr/bin/env python3
# Copyright (c) 2026, Gonzalo De Pablo
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
import os


def pytest_addoption(parser):
    """Add custom command line options for cocotb tests."""
    parser.addoption(
        "--sim",
        action="store",
        default=os.environ.get("SIM", "questa"),
        help="Simulator to use (default: questa)"
    )

