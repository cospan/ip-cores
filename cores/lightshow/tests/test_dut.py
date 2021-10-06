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
from lightshow_driver import LightshowDriver

CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    #Fork any simulation specific co-routines
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
    #cocotb.fork(my_sim_coroutine(dut))

# A simulation specific co-routine to stimulate the DUT in some way
#       At the moment do nothing
async def my_sim_coroutine(dut):
    while True:
        await Timer(CLK_PERIOD * 20)
        #Perform an operation ever 20 clock cycles
        await Timer(CLK_PERIOD * 20)

async def reset_dut(dut):
    dut.rst <= 1
    await Timer(CLK_PERIOD * 2)
    dut.rst <= 0
    await Timer(CLK_PERIOD * 2)

@cocotb.test(skip = False)
async def test_read_version(dut):
    """
    Description:
        Read Back the version

    Test ID: 0

    Expected Results:
        Read from the version register
    """
    dut.test_id <= 0
    dut._log.setLevel(logging.WARNING)
    setup_dut(dut)
    driver = LightshowDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    await reset_dut(dut)

    # Read the version
    version = await driver.get_version()
    # Reach into the design to get the actual version value (bypassing AXI)
    dut_version = dut.dut.w_version.value
    dut._log.debug ("Dut Version: %s" % dut_version)
    dut._log.debug ("Version: 0x%08X" % version)
    await Timer(CLK_PERIOD * 20)
    dut._log.debug("Done")
    assert dut_version == version

@cocotb.test(skip = False)
async def test_manual_pwm_color(dut):
    """
    Description:
        Write the entire control register

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    dut.test_id <= 1
    dut._log.setLevel(logging.WARNING)
    setup_dut(dut)
    driver = LightshowDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    await reset_dut(dut)

    #Make PWM really short at first
    # Red on 1/256, Green 10/256, Blue 256/256
    await driver.set_manual_color(0x01EFFF)
    await driver.enable_rgb(True)
    await Timer(CLK_PERIOD * 3000)

@cocotb.test(skip = False)
async def test_color_state_no_transition(dut):
    """
    Description:
        Write the entire control register

    Test ID: 2

    Expected Results:
        Read from the version register
    """
    dut.test_id <= 2
    dut._log.setLevel(logging.WARNING)
    setup_dut(dut)
    driver = LightshowDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    await reset_dut(dut)

    await driver.set_state_pwm_length(1)
    await driver.set_state_transition_length(0)
    #await driver.enable_auto(True)

    #Make PWM really short at first
    await driver.set_state_color(0, 0x01EFFF)
    await driver.set_state_color(1, 0x555555)
    await driver.set_state_color(2, 0xAAAAAA)
    await driver.set_state_count(3)

    await driver.enable_auto(True)
    await driver.enable_rgb(True)
    await Timer(CLK_PERIOD * 10000)



@cocotb.test(skip = True)
async def test_color_state_with_transition(dut):
    """
    Description:
        Write the entire control register
        NOTE: This test will take a LONG time!

    Test ID: 3

    Expected Results:
        Read from the version register
    """
    dut.test_id <= 3
    dut._log.setLevel(logging.WARNING)
    setup_dut(dut)
    driver = LightshowDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    await reset_dut(dut)

    await driver.set_state_pwm_length(2)
    #await driver.set_state_transition_length(2)
    #await driver.set_state_transition_length(3)
    await driver.set_state_transition_length(13)
    #await driver.set_state_transition_length(4)
    #await driver.set_state_transition_length(5)

    #Make PWM really short at first
    #await driver.set_state_color(0, 0x01EFFF)
    #await driver.set_state_color(1, 0xFFEF01)
    #await driver.set_state_color(2, 0x000000)
    #await driver.set_state_color(3, 0xFFFFFF)
    #await driver.set_state_count(4)

    await driver.set_state_color(0, 0xFF0000)
    await driver.set_state_color(1, 0x00FF00)
    await driver.set_state_color(2, 0x0000FF)
    await driver.set_state_color(3, 0x000000)
    await driver.set_state_count(3)

    await driver.enable_auto(True)
    await driver.enable_rgb(True)
    await Timer(CLK_PERIOD * 10000)


