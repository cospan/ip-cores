import os
import cocotb
import logging
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge

from axis_driver import AXISSource
from fps_counter_driver import FPSCounterDriver

CLK_PERIOD = 10
TEST_CLOCK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


#TODO: Write Test that verifies the nubmer of lines are correct
#TODO: Write Test that verifies the number of pixels are correct
#TODO: Write Test that verifies the frames per second is correct
#TODO: Write Test that verifies the row lenth differens flag works correctly


def setup_dut(dut):
    #Fork any simulation specific co-routines
    #cocotb.fork(my_sim_coroutine(dut))
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

# A simulation specific co-routine to stimulate the DUT in some way
#       At the moment do nothing
async def my_sim_coroutine(dut):
    while True:
        await Timer(CLK_PERIOD * 20)
        #Perform an operation ever 20 clock cycles
        await Timer(CLK_PERIOD * 20)

async def reset_dut(dut):
    dut.rst <= 1
    await Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    await Timer(CLK_PERIOD * 10)

@cocotb.test(skip = False)
async def test_read_version(dut):
    """
    Description:
        Read Back the version register using the AXI interface
        Verify that the value read back using the AXI interface
        matches the value that was read back directly

    Test ID: 0

    Expected Results:
        The value read using the AXI interface is the same as the value
        within the version register
    """
    dut._log.setLevel(logging.WARNING)
    dut.test_id <= 0
    setup_dut(dut)
    driver = FPSCounterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
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
async def test_boilerplate(dut):
    """
    Description:
        Write a value into the control register using AXI
        Read the value of the control register back directly
        Verify that the value written using AXI matches the value
            that was injected

    Test ID: 1

    Expected Results:
        The value in the control register is the same as the value
        written using the AXI interface
    """
    dut._log.setLevel(logging.WARNING)
    dut.test_id <= 1
    setup_dut(dut)
    driver = FPSCounterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_source = AXISSource(dut, "axis_in", dut.clk, dut.rst)
    await reset_dut(dut)
    await axis_source.reset()
    await RisingEdge(dut.clk)
    ARRAY_SIZE = 16
    data = [range(ARRAY_SIZE)]
    user = [0] * ARRAY_SIZE
    user[0] = 1


    await driver.set_clock_period(TEST_CLOCK_PERIOD)


    await Timer(CLK_PERIOD * 20)
    SPACING = 20
    # Send a frame that is 4 rows, twice
    for r in range(4):
        await Timer(CLK_PERIOD * SPACING)
        await axis_source.send_raw_data(data, user=user)
        await Timer(CLK_PERIOD * SPACING)
        await axis_source.send_raw_data(data, user=None)
        await Timer(CLK_PERIOD * SPACING)
        await axis_source.send_raw_data(data, user=None)
        await Timer(CLK_PERIOD * SPACING)
        await axis_source.send_raw_data(data, user=None)


    await Timer(CLK_PERIOD * 100)


    #my_control = 0x01234567
    #await driver.set_control(my_control)
    #dut_control = dut.dut.r_control.value
    #dut._log.debug ("Control: 0x%08X" % dut.dut.r_control.value)
    #await Timer(CLK_PERIOD * 20)
    dut._log.debug("Done")
    #assert dut_control == my_control

#@cocotb.test(skip = False)
#async def test_read_control(dut):
#    """
#    Description:
#        Inject a value into the control register directly
#        Use the AXI interface to read the value of the control register
#        Verify the value that was read using AXI is the same as the
#            value injected
#
#    Test ID: 2
#
#    Expected Results:
#        The value read using AXI interface is the same as the value injected
#    """
#    dut._log.setLevel(logging.WARNING)
#    dut.test_id <= 2
#    setup_dut(dut)
#    driver = FPSCounterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
#    await reset_dut(dut)
#
#    my_control = 0xFEDCBA98
#    #dut.dut.r_control.value = my_control
#    #control = await driver.get_control()
#    #dut._log.info ("Control: 0x%08X" % control)
#    #await Timer(CLK_PERIOD * 20)
#    dut._log.info("Done")
#    #assert control == my_control

