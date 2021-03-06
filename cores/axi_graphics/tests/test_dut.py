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

COLOR_MAGENTA  = 0xFFFF00
COLOR_CYAN     = 0x00FFFF
COLOR_GRAY     = 0x7F7F7F
COLOR_BLACK    = 0x000000
COLOR_RED      = 0xFF0000
COLOR_ORANGE   = 0xFF0080
COLOR_YELLOW   = 0xFF00FF
COLOR_GREEN    = 0x0000FF
COLOR_BLUE     = 0x00FF00
COLOR_PURPLE   = 0x80FF00
COLOR_WHITE    = 0xFFFFFF


CURRENT_FRAME = None

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

async def capture_frame(dut, height, width, ref_frame, display = False):
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)
    for y in range (height):
        await(axis_sink.receive())

    rdata = axis_sink.read_data()
    if display:
        for y in range (height):
            for x in range(width):
                print (" %08X" % rdata[y][x], end='')
            print ("")

    # Compare the reference image with the received data
    for y in range (height):
        for x in range(width):
            assert (ref_frame[y][x] == rdata[y][x])

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
async def test_colorbars(dut):
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
    ref_frame = [[0] * WIDTH] * HEIGHT
    #ref_frame = [[0 for i in range (WIDTH)] for j in range(HEIGHT)]
    #print ("Ref Frame: %s" % ref_frame)

    for y in range (HEIGHT):
        for x in range (WIDTH):
            cb_index = (x // (WIDTH // 8))
            color = 0x00000000

            if cb_index == 0:
                color = COLOR_BLACK
            elif cb_index == 1:
                color = COLOR_RED
            elif cb_index == 2:
                color = COLOR_ORANGE
            elif cb_index == 3:
                color = COLOR_YELLOW
            elif cb_index == 4:
                color = COLOR_GREEN
            elif cb_index == 5:
                color = COLOR_BLUE
            elif cb_index == 6:
                color = COLOR_PURPLE
            elif cb_index == 7:
                color = COLOR_WHITE


            ref_frame[y][x] = color
            ref_frame[y][x] |= 0xFF000000

    #print ("Reference Frame")
    #for y in range (HEIGHT):
    #    for x in range (WIDTH):
    #        print (" %08X" % ref_frame[y][x], end='')
    #    print ("")
    #print("")


    setup_dut(dut)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)

    dut.test_id <= 1
    await reset_dut(dut)
    await axis_sink.reset()

    cocotb.fork(capture_frame(dut, HEIGHT, WIDTH, ref_frame, False))
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
    refA = [1, 1]
    refB = [3, 2]

    setup_dut(dut)
    driver = AXIGraphicsDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)

    ref_frame = [[0 for x in range(WIDTH)] for y in range(HEIGHT)]

    for y in range (HEIGHT):
        for x in range (WIDTH):
            #print ("%d, %d " % (x, y), end='')
            if (y >= refA[1]) and (x >= refA[0]) and (y <= refB[1]) and (x <= refB[0]):
                ref_frame[y][x] = COLOR_WHITE | 0xFF000000
                #ref_frame[y][x] |= COLOR_WHITE
                #print ("BOX  ", end='')
            else:
                ref_frame[y][x] = 0xFF000000
                #print ("NONE ", end='')
        #print ("")

    #print ("Reference Frame")
    #for y in range (HEIGHT):
    #    for x in range (WIDTH):
    #        print (" %d, %d: %08X" % (x, y, ref_frame[y][x]), end='')
    #    print ("")
    #print("")

    dut.test_id <= 2
    await reset_dut(dut)
    await axis_sink.reset()

    #cocotb.fork(capture_frame(dut, HEIGHT, WIDTH, ref_frame, True))
    cocotb.fork(capture_frame(dut, HEIGHT, WIDTH, ref_frame, False))
    await driver.set_width(WIDTH)
    await driver.set_height(HEIGHT)
    await driver.set_ref0_xy(refA[0], refA[1])
    await driver.set_ref1_xy(refB[0], refB[1])
    await driver.set_mode(6)
    await driver.enable(True)
    dut._log.info("Done")
    await Timer(CLK_PERIOD * 200)


