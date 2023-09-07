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
TEST_CLOCK_FREQUENCY = 400

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)


#TODO: Write Test that verifies the frames per second is correct


def setup_dut(dut):
    #Fork any simulation specific co-routines
    #cocotb.start_soon(my_sim_coroutine(dut))
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD).start())

# A simulation specific co-routine to stimulate the DUT in some way
#       At the moment do nothing
async def my_sim_coroutine(dut):
    while True:
        await Timer(CLK_PERIOD * 20)
        #Perform an operation ever 20 clock cycles
        await Timer(CLK_PERIOD * 20)

async def reset_dut(dut):
    dut.rst.value = 1
    await Timer(CLK_PERIOD * 10)
    dut.rst.value = 0
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
    dut.test_id.value = 0
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
    dut.test_id.value = 1
    setup_dut(dut)
    driver = FPSCounterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_source = AXISSource(dut, "axis_in", dut.clk, dut.rst)
    await reset_dut(dut)
    await axis_source.reset()
    await RisingEdge(dut.clk)
    LINE_LENGTH = 16
    data = [range(LINE_LENGTH)]
    user = [0] * LINE_LENGTH
    user[0] = 1


    await driver.set_clock_period(TEST_CLOCK_FREQUENCY)


    await Timer(CLK_PERIOD * 20)
    SPACING = 20
    # Send a frame that is 4 rows, twice
    FRAME_COUNT = 4
    LINE_COUNT = 6
    for r in range(FRAME_COUNT):
        await axis_source.send_raw_data(data, user=user)
        await Timer(CLK_PERIOD * SPACING)
        for i in range (LINE_COUNT - 1):
            await axis_source.send_raw_data(data, user=None)
            await Timer(CLK_PERIOD * SPACING)

    await Timer(CLK_PERIOD * 100)

    frames = await driver.get_total_frames()
    line_count = await driver.get_lines_per_frame()
    line_length = await driver.get_pixels_per_row()

    dut._log.debug("Done")
    assert FRAME_COUNT == frames
    assert LINE_COUNT == line_count
    assert LINE_LENGTH == line_length


@cocotb.test(skip = False)
async def test_rows_not_equal(dut):
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
    dut.test_id.value = 2
    setup_dut(dut)
    driver = FPSCounterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_source = AXISSource(dut, "axis_in", dut.clk, dut.rst)
    await reset_dut(dut)
    await axis_source.reset()
    await RisingEdge(dut.clk)
    LINE_LENGTH = 16
    data = [range(LINE_LENGTH)]
    user = [0] * LINE_LENGTH
    user[0] = 1

    error_data = [range(LINE_LENGTH + 1)]
    user = [0] * (LINE_LENGTH + 1)
    user[0] = 1


    await driver.set_clock_period(TEST_CLOCK_FREQUENCY)


    await Timer(CLK_PERIOD * 20)
    SPACING = 20
    # Send a frame that is 4 rows, twice
    LINE_COUNT = 6
    for r in range(2):
        await axis_source.send_raw_data(data, user=user)
        await Timer(CLK_PERIOD * SPACING)
        for i in range (LINE_COUNT - 1):
            await axis_source.send_raw_data(data, user=None)
            await Timer(CLK_PERIOD * SPACING)
    rows_error = await driver.are_rows_equal()
    assert not rows_error

    for r in range(2):
        await axis_source.send_raw_data(data, user=user)
        await Timer(CLK_PERIOD * SPACING)
        for i in range (LINE_COUNT - 1):
            # Insert Row Error
            await axis_source.send_raw_data(error_data, user=None)
            await Timer(CLK_PERIOD * SPACING)


    await Timer(CLK_PERIOD * 100)
    # Should have an error now!
    rows_error = await driver.are_rows_equal()
    assert rows_error
    dut._log.debug("Done")


@cocotb.test(skip = False)
async def test_lines_not_equal(dut):
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
    dut.test_id.value = 3
    setup_dut(dut)
    driver = FPSCounterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_source = AXISSource(dut, "axis_in", dut.clk, dut.rst)
    await reset_dut(dut)
    await axis_source.reset()
    await RisingEdge(dut.clk)
    LINE_LENGTH = 16
    data = [range(LINE_LENGTH)]
    user = [0] * LINE_LENGTH
    user[0] = 1

    await driver.set_clock_period(TEST_CLOCK_FREQUENCY)


    await Timer(CLK_PERIOD * 20)
    SPACING = 20
    # Send a frame that is 4 rows, twice
    LINE_COUNT = 6
    for r in range(2):
        await axis_source.send_raw_data(data, user=user)
        await Timer(CLK_PERIOD * SPACING)
        for i in range (LINE_COUNT - 1):
            await axis_source.send_raw_data(data, user=None)
            await Timer(CLK_PERIOD * SPACING)
    lines_error = await driver.are_lines_equal()
    assert not lines_error

    LINE_COUNT = 3
    for r in range(2):
        await axis_source.send_raw_data(data, user=user)
        await Timer(CLK_PERIOD * SPACING)
        for i in range (LINE_COUNT - 1):
            # Insert Row Error
            await axis_source.send_raw_data(data, user=None)
            await Timer(CLK_PERIOD * SPACING)


    await Timer(CLK_PERIOD * 100)
    # Should have an error now!
    lines_error = await driver.are_lines_equal()
    assert lines_error
    dut._log.debug("Done")


