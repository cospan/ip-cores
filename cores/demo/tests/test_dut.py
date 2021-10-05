import os
import sys
import cocotb
import logging
from cocotb.result import TestFailure
from cocotb.clock import Clock
import time
from array import array as Array
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge

from demo_driver import DemoDriver

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    #Fork any simulation specific co-routines
    #cocotb.fork(my_sim_coroutine(dut))
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

# A simulation specific co-routine to stimulate the DUT in some way
#       At the moment do nothing
@cocotb.coroutine
def my_sim_coroutine(dut):
    while True:
        yield Timer(CLK_PERIOD * 20)
        #Perform an operation ever 20 clock cycles
        yield Timer(CLK_PERIOD * 20)

@cocotb.coroutine
def reset_dut(dut):
    dut.rst <= 1
    yield Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 10)

@cocotb.test(skip = False)
def test_read_version(dut):
    """
    Description:
        Read Back the version

    Test ID: 0

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    setup_dut(dut)
    demo = DemoDriver(dut, dut.clk, dut.rst, CLK_PERIOD, False)
    dut.test_id <= 0
    yield reset_dut(dut)

    # Read the version
    version = yield demo.get_version()
    # Reach into the design to get the actual version value (bypassing AXI)
    dut_version = dut.dut.w_version.value
    dut._log.debug ("Dut Version: %s" % dut_version)
    dut._log.debug ("Version: 0x%08X" % version)
    yield Timer(CLK_PERIOD * 20)
    dut._log.debug("Done")
    assert dut_version == version

@cocotb.test(skip = False)
def test_write_control(dut):
    """
    Description:
        Write the entire control register

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    demo = DemoDriver(dut, dut.clk, dut.rst, CLK_PERIOD, False)
    dut.test_id <= 1
    yield reset_dut(dut)

    my_control = 0x01234567
    yield demo.set_control(my_control)
    dut_control = dut.dut.r_control.value
    dut._log.debug ("Control: 0x%08X" % dut.dut.r_control.value)
    yield Timer(CLK_PERIOD * 20)
    dut._log.debug("Done")
    assert dut_control == my_control

@cocotb.test(skip = False)
def test_read_control(dut):
    """
    Description:
        Read the entire control register

    Test ID: 2

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    demo = DemoDriver(dut, dut.clk, dut.rst, CLK_PERIOD, False)
    dut.test_id <= 2
    yield reset_dut(dut)

    my_control = 0xFEDCBA98
    dut.dut.r_control.value = my_control
    control = yield demo.get_control()
    dut._log.info ("Control: 0x%08X" % control)
    yield Timer(CLK_PERIOD * 20)
    dut._log.info("Done")
    assert control == my_control

@cocotb.test(skip = False)
def test_write_demo(dut):
    """
    Description:
        Write the entire demo register

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    demo = DemoDriver(dut, dut.clk, dut.rst, CLK_PERIOD, False)
    dut.test_id <= 3
    yield reset_dut(dut)

    my_demo = 0xABBA600D    # ABBA is a G00D band
    yield demo.set_demo(my_demo)
    dut_demo = dut.dut.r_demo.value
    dut._log.debug ("Control: 0x%08X" % dut.dut.r_demo.value)
    yield Timer(CLK_PERIOD * 20)
    dut._log.debug("Done")
    assert dut_demo == my_demo

@cocotb.test(skip = False)
def test_read_demo(dut):
    """
    Description:
        Read the entire demo register

    Test ID: 2

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    demo = DemoDriver(dut, dut.clk, dut.rst, CLK_PERIOD, False)
    dut.test_id <= 4
    yield reset_dut(dut)

    my_demo = 0xFEEDACA7    # Always remember to FEED A CAT
    dut.dut.r_demo.value = my_demo
    demo = yield demo.get_demo()
    dut._log.info ("Control: 0x%08X" % demo)
    yield Timer(CLK_PERIOD * 20)
    dut._log.info("Done")
    assert demo == my_demo

