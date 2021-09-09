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

from cocotb_bus.drivers.amba import AXI4LiteMaster
from lightshow_driver import lightshowDriver

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    #Fork any simulation specific co-routines
    #cocotb.fork(my_sim_coroutine(dut))
    pass

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
    yield Timer(CLK_PERIOD * 2)
    dut.rst <= 0
    yield Timer(CLK_PERIOD * 2)

@cocotb.test(skip = True)
def test_read_version(dut):
    """
    Description:
        Read Back the version

    Test ID: 0

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    lightshow = lightshowDriver(dut, CLK_PERIOD, False)
    yield reset_dut(dut)
    dut.test_id <= 0

    # Read the version
    version = yield lightshow.get_version()
    # Reach into the design to get the actual version value (bypassing AXI)
    dut_version = dut.dut.w_version.value
    dut._log.debug ("Dut Version: %s" % dut_version)
    dut._log.debug ("Version: 0x%08X" % version)
    yield Timer(CLK_PERIOD * 20)
    dut._log.debug("Done")
    assert dut_version == version

@cocotb.test(skip = True)
def test_manual_pwm_color(dut):
    """
    Description:
        Write the entire control register

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    lightshow = lightshowDriver(dut, CLK_PERIOD, False)
    yield reset_dut(dut)
    dut.test_id <= 1

    #Make PWM really short at first
    # Red on 1/256, Green 10/256, Blue 256/256
    yield lightshow.set_manual_color(0x01EFFF)
    yield lightshow.enable_rgb(True)
    yield Timer(CLK_PERIOD * 3000)

@cocotb.test(skip = True)
def test_color_state_no_transition(dut):
    """
    Description:
        Write the entire control register

    Test ID: 2

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    lightshow = lightshowDriver(dut, CLK_PERIOD, False)
    yield reset_dut(dut)
    dut.test_id <= 2

    yield lightshow.set_state_pwm_length(1)
    yield lightshow.set_state_transition_length(0)
    #yield lightshow.enable_auto(True)



    #Make PWM really short at first
    yield lightshow.set_state_color(0, 0x01EFFF)
    yield lightshow.set_state_color(1, 0x555555)
    yield lightshow.set_state_color(2, 0xAAAAAA)
    yield lightshow.set_state_count(3)


    yield lightshow.enable_auto(True)
    yield lightshow.enable_rgb(True)
    yield Timer(CLK_PERIOD * 10000)



@cocotb.test(skip = False)
def test_color_state_with_transition(dut):
    """
    Description:
        Write the entire control register

    Test ID: 2

    Expected Results:
        Read from the version register
    """
    setup_dut(dut)
    lightshow = lightshowDriver(dut, CLK_PERIOD, False)
    yield reset_dut(dut)
    dut.test_id <= 2

    yield lightshow.set_state_pwm_length(2)
    #yield lightshow.set_state_transition_length(2)
    #yield lightshow.set_state_transition_length(3)
    yield lightshow.set_state_transition_length(13)
    #yield lightshow.set_state_transition_length(4)
    #yield lightshow.set_state_transition_length(5)

    #Make PWM really short at first
    #yield lightshow.set_state_color(0, 0x01EFFF)
    #yield lightshow.set_state_color(1, 0xFFEF01)
    #yield lightshow.set_state_color(2, 0x000000)
    #yield lightshow.set_state_color(3, 0xFFFFFF)
    #yield lightshow.set_state_count(4)

    yield lightshow.set_state_color(0, 0xFF0000)
    yield lightshow.set_state_color(1, 0x00FF00)
    yield lightshow.set_state_color(2, 0x0000FF)
    yield lightshow.set_state_color(3, 0x000000)
    yield lightshow.set_state_count(3)




    yield lightshow.enable_auto(True)
    yield lightshow.enable_rgb(True)
    yield Timer(CLK_PERIOD * 100000)


