import os
import cocotb
import logging
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge

from axis_driver import AXISSink
from axi_graphics_driver import AXIGraphicsDriver

CLK_PERIOD = 2
AXIS_CLK_PERIOD = 2

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

CURRENT_FRAME = None

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

async def capture_frame(dut, height, width):
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)
    for y in range (height):
        await(axis_sink.receive())

    rdata = axis_sink.read_data()
    for y in range (height):
        for x in range(width):
            print (" %08X" % rdata[y][x], end='')
        print ("")

async def reset_dut(dut):
    dut.rst <= 1
    await RisingEdge(dut.clk)
    await Timer(CLK_PERIOD * 10)
    dut.rst <= 0
    await Timer(CLK_PERIOD * 10)

@cocotb.test(skip = False)
async def read_version(dut):
    """
    Description:
        Very Basic Functionality

    Test ID: 0

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    WIDTH = 640
    HEIGHT = 480
    setup_dut(dut)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    dut.test_id <= 0
    await reset_dut(dut)
    version = await driver.get_version()
    dut._log.info ("Version: 0x%08X" % version)
    dut._log.info("Done")
    await Timer(CLK_PERIOD * 20)

@cocotb.test(skip = False)
async def boilerplate(dut):
    """
    Description:
        Very Basic Functionality

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    WIDTH = 16
    #WIDTH = 128
    HEIGHT = 4
    setup_dut(dut)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)

    dut.test_id <= 1
    await reset_dut(dut)
    await axis_sink.reset()

    cocotb.fork(capture_frame(dut, HEIGHT, WIDTH))
    await driver.set_width(WIDTH)
    await driver.set_height(HEIGHT)
    await driver.set_mode(5)
    await driver.enable(True)
    dut._log.info("Done")
    await Timer(CLK_PERIOD * 200)


@cocotb.test(skip = False)
async def draw_square(dut):
    """
    Description:
        Very Basic Functionality

    Test ID: 2

    Expected Results:
        Read from the version register
    """
    WIDTH = 16
    HEIGHT = 4
    setup_dut(dut)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)

    dut.test_id <= 2
    await reset_dut(dut)
    await axis_sink.reset()

    cocotb.fork(capture_frame(dut, HEIGHT, WIDTH))
    await driver.set_width(WIDTH)
    await driver.set_height(HEIGHT)
    await driver.set_ref0_xy(1, 1)
    await driver.set_ref1_xy(3, 2)
    await driver.set_mode(6)
    await driver.enable(True)
    dut._log.info("Done")
    await Timer(CLK_PERIOD * 200)


