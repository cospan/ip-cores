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

def setup_dut(dut, width, height):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
    #cocotb.fork(Clock(dut.axis_clk, AXIS_CLK_PERIOD).start())
    cocotb.fork(frame_reader(dut, width, height))

async def frame_reader(dut, width:int, height:int):
    global CURRENT_FRAME
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)
    #while True:
    CURRENT_FRAME = []
    cocotb.fork(axis_sink.receive())
    rdata = axis_sink.read_data()
    CURRENT_FRAME.append(rdata)

    #for y in range(height):
    #    read_coroutine = axis_sink.read(size = width)
    #    line = await read_coroutine
    #    #print ("%s" % line)
    #    d = [int(line[i]) for i in range(len(line))]
    #    CURRENT_FRAME.append(d)
    dut._log.info("frame finished\n");
    #for y in range (height):
    #    dut._log.info("     %s" % str(CURRENT_FRAME[y]))
    #dut._log.debug("%s" % str(CURRENT_FRAME))
    print_frame(CURRENT_FRAME)

def print_frame(frame):
    height = len(frame)
    width = len(frame[0])
    for y in range(height):
        print ("   ", end='')
        for x in range(width):
            print (" %08X" % frame[y][x], end='')
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
    setup_dut(dut, WIDTH, HEIGHT)
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
    HEIGHT = 4
    setup_dut(dut, WIDTH, HEIGHT)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    dut.test_id <= 1
    await reset_dut(dut)
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
    setup_dut(dut, WIDTH, HEIGHT)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    dut.test_id <= 2
    await reset_dut(dut)
    await driver.set_width(WIDTH)
    await driver.set_height(HEIGHT)
    await driver.set_ref0_xy(1, 1)
    await driver.set_ref1_xy(14, 2)
    await driver.set_mode(6)
    await driver.enable(True)
    dut._log.info("Done")
    await Timer(CLK_PERIOD * 200)


