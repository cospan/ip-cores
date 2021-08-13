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

from axis_driver import AXISSource
from axis_driver import AXISSink
from cocotb_bus.drivers.amba import AXI4LiteMaster
from demo_axi_streams_driver import DemoAXIStreamsDriver

CLK_PERIOD = 2
AXIS_CLK_PERIOD = 2

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "rtl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())
    cocotb.fork(Clock(dut.axis_clk, AXIS_CLK_PERIOD).start())

@cocotb.coroutine
def reset_dut(dut):
    dut.rst <= 1
    dut.axis_rst <= 1
    yield Timer(CLK_PERIOD * AXIS_CLK_PERIOD * 2)
    dut.rst <= 0
    dut.axis_rst <= 0
    yield Timer(CLK_PERIOD * AXIS_CLK_PERIOD * 2)

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
    dut.test_id <= 0
    setup_dut(dut)
    demo_axi_streams = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    yield reset_dut(dut)

    # Read the version
    version = yield demo_axi_streams.get_version()
    # Reach into the design to get the actual version value (bypassing AXI)
    dut_version = dut.dut.w_version.value
    dut._log.info ("Dut Version: %s" % dut_version)
    dut._log.info ("Version: 0x%08X" % version)
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
    dut._log.setLevel(logging.WARNING)
    dut.test_id <= 1
    setup_dut(dut)
    demo_axi_streams = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    yield reset_dut(dut)

    my_control = 0x01234567
    yield demo_axi_streams.set_control(my_control)
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
    dut._log.setLevel(logging.WARNING)
    dut.test_id <= 2
    setup_dut(dut)
    demo_axi_streams = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    yield reset_dut(dut)

    my_control = 0xFEDCBA98
    dut.dut.r_control.value = my_control
    control = yield demo_axi_streams.get_control()
    dut._log.info ("Control: 0x%08X" % control)
    yield Timer(CLK_PERIOD * 20)
    dut._log.info("Done")
    assert control == my_control

@cocotb.test(skip = False)
def test_axis_write(dut):
    """
    Description:
        Read the entire control register

    Test ID: 3

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    dut.test_id <= 3
    setup_dut(dut)
    demo_axi_streams = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    axis_source = AXISSource(dut, "axis_in", dut.axis_clk, dut.axis_rst)
    yield reset_dut(dut)

    yield axis_source.reset()
    yield RisingEdge(dut.clk)
    #yield reset_dut(dut)
    data = [range(16)]
    yield axis_source.send_raw_data(data)

    yield Timer(CLK_PERIOD * 100)


@cocotb.test(skip = False)
def test_axis_write_and_read(dut):
    """
    Description:
        Read the entire control register

    Test ID: 4

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    #dut._log.setLevel(logging.INFO)
    DATA_COUNT = 16
    dut.test_id <= 4
    setup_dut(dut)
    demo_axi_streams        = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    axis_source = AXISSource(dut, "axis_in",  dut.axis_clk, dut.axis_rst)
    axis_sink   = AXISSink  (dut, "axis_out", dut.axis_clk, dut.axis_rst)
    yield reset_dut(dut)
    #yield axis_source.reset()
    #yield axis_sink.reset()
    sdata = [list(range(DATA_COUNT))]

    cocotb.fork(axis_sink.receive())
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    yield axis_source.send_raw_data(sdata)
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    rdata = axis_sink.read_data()
    assert len(rdata) == len(sdata)
    for i in range(len(rdata)):
        assert len(rdata[i]) == len(sdata[i])

    for i in range(len(rdata)):
        for j in rdata[i]:
            assert rdata[i][j] == sdata[i][j]


@cocotb.test(skip = False)
def test_axis_write_and_read_with_source_idle(dut):
    """
    Description:
        Read the entire control register

    Test ID: 5

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    #dut._log.setLevel(logging.INFO)
    DATA_COUNT = 16
    dut.test_id <= 5
    setup_dut(dut)
    demo_axi_streams        = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    axis_source = AXISSource(dut, "axis_in",  dut.axis_clk, dut.axis_rst)
    axis_sink   = AXISSink  (dut, "axis_out", dut.axis_clk, dut.axis_rst)
    yield reset_dut(dut)
    #yield axis_source.reset()
    #yield axis_sink.reset()
    sdata = [list(range(DATA_COUNT))]
    idle_list = [0] * DATA_COUNT
    idle_list[1] = 1
    idle_list[2] = 1
    idle_list[4] = 1
    idle_list[9] = 1

    axis_source.insert_idle_list(idle_list)

    cocotb.fork(axis_sink.receive())
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    yield axis_source.send_raw_data(sdata)
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    rdata = axis_sink.read_data()
    assert len(rdata) == len(sdata)
    for i in range(len(rdata)):
        assert len(rdata[i]) == len(sdata[i])

    for i in range(len(rdata)):
        for j in rdata[i]:
            assert rdata[i][j] == sdata[i][j]


@cocotb.test(skip = False)
def test_axis_write_and_read_with_sink_back_preassure(dut):
    """
    Description:
        Read the entire control register

    Test ID: 6

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    #dut._log.setLevel(logging.INFO)
    DATA_COUNT = 16
    dut.test_id <= 6
    setup_dut(dut)
    demo_axi_streams        = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    axis_source = AXISSource(dut, "axis_in",  dut.axis_clk, dut.axis_rst)
    axis_sink   = AXISSink  (dut, "axis_out", dut.axis_clk, dut.axis_rst)
    yield reset_dut(dut)
    #yield axis_source.reset()
    #yield axis_sink.reset()

    sdata = [list(range(DATA_COUNT))]
    bp_list = [0] * DATA_COUNT

    bp_list[DATA_COUNT - 1] = 1
    bp_list[2] = 1
    axis_sink.insert_backpreassure_list(bp_list)

    cocotb.fork(axis_sink.receive())
    yield RisingEdge(dut.clk)
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    yield axis_source.send_raw_data(sdata)
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    rdata = axis_sink.read_data()
    assert len(rdata) == len(sdata)
    for i in range(len(rdata)):
        assert len(rdata[i]) == len(sdata[i])

    for i in range(len(rdata)):
        for j in rdata[i]:
            assert rdata[i][j] == sdata[i][j]

@cocotb.test(skip = False)
def test_axis_write_and_read_with_sink_idle_and_back_preassure(dut):
    """
    Description:
        Read the entire control register

    Test ID: 7

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    #dut._log.setLevel(logging.INFO)
    DATA_COUNT = 16
    dut.test_id <= 7
    setup_dut(dut)
    demo_axi_streams        = DemoAXIStreamsDriver(dut, "aximl", dut.clk, dut.rst, debug = False)
    axis_source = AXISSource(dut, "axis_in",  dut.axis_clk, dut.axis_rst)
    axis_sink   = AXISSink  (dut, "axis_out", dut.axis_clk, dut.axis_rst)
    yield reset_dut(dut)

    sdata = [list(range(DATA_COUNT))]
    bp_list = [0] * DATA_COUNT

    bp_list[DATA_COUNT - 1] = 1
    bp_list[2] = 1

    idle_list = [0] * DATA_COUNT
    idle_list[1] = 1

    axis_sink.insert_backpreassure_list(bp_list)
    axis_source.insert_idle_list(idle_list)

    cocotb.fork(axis_sink.receive())

    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    yield axis_source.send_raw_data(sdata)
    yield Timer(AXIS_CLK_PERIOD * CLK_PERIOD * 20)
    rdata = axis_sink.read_data()
    assert len(rdata) == len(sdata)
    for i in range(len(rdata)):
        assert len(rdata[i]) == len(sdata[i])

    for i in range(len(rdata)):
        for j in rdata[i]:
            assert rdata[i][j] == sdata[i][j]

