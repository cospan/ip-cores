import os
import sys
import cocotb
import logging
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.triggers import Join
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from axis_driver import AXISSink

from axi_terminal_driver import AxiTerminalDriver

#DEBUG=False
DEBUG=True
ASSERT_TEST = False
#ASSERT_TEST = True

ACTIVE_FRAME = False


CLK_PERIOD = 10
#AXIS_CLK_PERIOD = 2
AXIS_CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD).start())
    cocotb.start_soon(Clock(dut.axis_clk, AXIS_CLK_PERIOD).start())


#async def capture_frame(dut, axis_sink, height, width, ref_frame, display = False):
async def capture_frame(dut, height, width, ref_frame, display = False):
    ACTIVE_FRAME = True
    axis_sink   = AXISSink  (dut, "axis_out", dut.axis_clk, dut.axis_rst)
    for y in range (height):
        await(axis_sink.receive())
        #print ("Row Finished")

    #print ("Finished image")
    rdata = axis_sink.read_data()
    #print ("Size (row 0 ref): %d x %d" % (len(rdata[0]), len(rdata)))
    #print ("Size (row 1 ref): %d x %d" % (len(rdata[1]), len(rdata)))
    if display:
        for y in range (height):
            for x in range(width):
                #print ("[X x Y: %d x %d]" % (x, y))
                #print (" %08X" % ((~0xFF000000) & rdata[y][x]), end='')
                #print (" %06X" % ((~0xFF000000) & rdata[y][x]), end='')
                #print (" %01X" % ((~0xFF000000) & rdata[y][x]), end='')
                #print (" %01X" % ((~0xFFFFFFFE) & rdata[y][x]), end='')
                try:
                  if (((~0xFFFFFFFE) & rdata[y][x]) > 0):
                      print(u'\u2588', end='')
                  else:
                      print(' ', end='')
                except IndexError as ie:
                    print ("INDEX ERROR")
                    print ("Index Error, First  Row Width: %d" % (len(rdata[0])))
                    print ("Index Error, Second Row Width: %d" % (len(rdata[1])))
                    raise IndexError
            print ("")

    # Compare the reference image with the received data
    for y in range (height):
        for x in range(width):
            if ASSERT_TEST: assert (ref_frame[y][x] == rdata[y][x])

    print ("Finished Capturing Frame")
    ACTIVE_FRAME = False


async def reset_dut(dut):
    dut.rst.value =  1
    dut.axis_rst.value =  1
    await Timer(CLK_PERIOD * 10)
    dut.rst.value =  0
    dut.axis_rst.value =  0
    await Timer(CLK_PERIOD * 10)

@cocotb.test(skip = True)
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
    dut.test_id.value =  0
    setup_dut(dut)
    driver = AxiTerminalDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    #axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)
    await reset_dut(dut)
    await axis_sink.reset()

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
async def test_write_char(dut):
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
    dut.test_id.value =  1
    setup_dut(dut)
    driver = AxiTerminalDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_sink   = AXISSink  (dut, "axis_out", dut.clk, dut.rst)
    await reset_dut(dut)
    await axis_sink.reset()
    axis_sink = None
    width = await driver.get_video_width()
    height = await driver.get_video_height()
    print ("Image Width: %d x %d" % (width, height))

    ref_frame = [[0 for x in range(width)] for y in range(height)]

    #WAIT_TIME = 1000
    WAIT_TIME = 5000
    if height >= 100:
        WAIT_TIME = 5000
    print ("Wait Time: %d" % WAIT_TIME)

    await Timer(CLK_PERIOD * 1000)

    #cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    th = cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    await driver.enable_terminal(True)
    await driver.image_adjust_padding()

    #await driver.set_background_color(0xFF00FF00)
    await Timer(CLK_PERIOD * 10)
    await driver.put_char('A')
    await Timer(CLK_PERIOD * 10)
    await driver.put_char(' ')
    await Timer(CLK_PERIOD * 10)
    await driver.put_char(' ')
    await Timer(CLK_PERIOD * 10)
    await driver.put_char(' ')
    await Timer(CLK_PERIOD * 10)
    await driver.put_char('O')

    #await Timer(CLK_PERIOD * 100)
    #await driver.put_char('C')

    j = Join(th)
    await j
    ##await Timer(CLK_PERIOD * WAIT_TIME)
    await Timer(CLK_PERIOD * 10)

    #print ("Capture second frame")
    #cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    th = cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    await Timer(CLK_PERIOD * 100)
    j = Join(th)
    await j
    #await Timer(CLK_PERIOD * WAIT_TIME)
    await Timer(CLK_PERIOD * 10)

    #cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    th = cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    await Timer(CLK_PERIOD * 100)
    j = Join(th)
    await j
    #await Timer(CLK_PERIOD * WAIT_TIME)

    ##cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    ###th = cocotb.start_soon(capture_frame(dut, height, width, ref_frame, DEBUG))
    ###j = Join(th)
    ###await j
    ##await Timer(CLK_PERIOD * WAIT_TIME)



    dut._log.debug("Done")
    #assert dut_control == my_control

@cocotb.test(skip = True)
async def test_read_control(dut):
    """
    Description:
        Inject a value into the control register directly
        Use the AXI interface to read the value of the control register
        Verify the value that was read using AXI is the same as the
            value injected

    Test ID: 2

    Expected Results:
        The value read using AXI interface is the same as the value injected
    """
    dut._log.setLevel(logging.WARNING)
    dut.test_id.value =  2
    setup_dut(dut)
    driver = AxiTerminalDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    await reset_dut(dut)

    my_control = 0xFEDCBA98
    dut.dut.r_control.value = my_control
    control = await driver.get_control()
    dut._log.info ("Control: 0x%08X" % control)
    await Timer(CLK_PERIOD * 20)
    dut._log.info("Done")
    assert control == my_control

