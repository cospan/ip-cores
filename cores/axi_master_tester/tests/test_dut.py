import os
import cocotb
import logging
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from array import array as Array

from axis_driver import AXISSource
from axis_driver import AXISSink
from cocotbext.axi import AxiBus, AxiSlave, MemoryRegion


from axi_master_tester_driver import AXIMasterTesterDriver


CLK_PERIOD = 10

MODULE_PATH = os.path.join(os.path.dirname(__file__), os.pardir, "hdl")
MODULE_PATH = os.path.abspath(MODULE_PATH)

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
    dut.test_id.value = 0
    setup_dut(dut)
    driver = AXIMasterTesterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
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
async def test_axi_write(dut):
    """
    Description:
        Read the entire control register

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    DATA_COUNT = 16
    ADDRESS = 0x0000
    dut.test_id.value = 2
    setup_dut(dut)
    driver = AXIMasterTesterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_source     = AXISSource(dut, "usr_w",  dut.clk, dut.rst)
    axis_sink       = AXISSink  (dut, "usr_r",  dut.clk, dut.rst)

    # Setup the AXI Slave
    axi_slave   = AxiSlave(AxiBus.from_prefix(dut, "axi_slave"), dut.clk, dut.rst, endian='big')
    region = MemoryRegion(2 ** axi_slave.read_if.address_width)
    axi_slave.target = region

    #test = [0x10, 0x15, 0x16, 0x17, 0x01, 0x02, 0x03, 0x04]
    #test = Array('B', (test))
    #await axi_slave.target.write(ADDRESS, test)
    #rdata = await axi_slave.target.read(ADDRESS, DATA_COUNT)
    #print ("Read: %s" % str(rdata))



    await reset_dut(dut)
    await axis_source.reset()
    await Timer(CLK_PERIOD * 50)

    if await driver.is_ready():
        dut._log.warning ("AXI Master Ready")
    else:
        dut._log.warning ("AXI Master NOT Ready")

    await driver.start_write_transaction(addr=ADDRESS, length=DATA_COUNT, user_id=0)

    version = await driver.get_version()
    sdata = [list(range(DATA_COUNT))]

    #cocotb.start_soon(axis_sink.receive())
    await Timer(CLK_PERIOD * 10)
    await axis_source.send_raw_data(sdata)
    await Timer(CLK_PERIOD * 50)
    #rdata = axis_sink.read_data()

    if await driver.is_ready():
        dut._log.warning ("AXI Master Ready")
    else:
        dut._log.warning ("AXI Master NOT Ready")

    await Timer(CLK_PERIOD * 100)

    rdata = await axi_slave.target.read(ADDRESS, DATA_COUNT)
    print ("Read: %s" % str(rdata))


    #assert len(rdata) == len(sdata)
    #for i in range(len(rdata)):
    #    assert len(rdata[i]) == len(sdata[i])

    #for i in range(len(rdata)):
    #    for j in rdata[i]:
    #        assert rdata[i][j] == sdata[i][j]


@cocotb.test(skip = False)
async def test_axi_read(dut):
    """
    Description:
        Read the entire control register

    Test ID: 1

    Expected Results:
        Read from the version register
    """
    dut._log.setLevel(logging.WARNING)
    DATA_COUNT = 16
    ADDRESS = 0x0000
    dut.test_id.value = 3
    setup_dut(dut)
    driver = AXIMasterTesterDriver(dut, dut.clk, dut.rst, CLK_PERIOD, name="aximl", debug=False)
    axis_source     = AXISSource(dut, "usr_w",  dut.clk, dut.rst)
    axis_sink       = AXISSink  (dut, "usr_r",  dut.clk, dut.rst)

    # Setup the AXI Slave
    axi_slave   = AxiSlave(AxiBus.from_prefix(dut, "axi_slave"), dut.clk, dut.rst, endian='big')
    region = MemoryRegion(2 ** axi_slave.read_if.address_width)
    axi_slave.target = region


    await reset_dut(dut)
    await axis_source.reset()
    await Timer(CLK_PERIOD * 50)

    if await driver.is_ready():
        dut._log.warning ("Ready ***********************")
    else:
        dut._log.warning ("NOT Ready &&&&&&&&&&&&&&&&")


    version = await driver.get_version()
    sdata = Array('B')
    for v in range(DATA_COUNT):
        sdata.append(v >> 24)
        sdata.append(v >> 16)
        sdata.append(v >>  8)
        sdata.append(v >>  0)
    #sdata = list(range(DATA_COUNT))
    #print ("SDATA: %s" % str(sdata))
    #sdata = Array('B', (sdata))
    await region.write(ADDRESS, sdata)
    await Timer(CLK_PERIOD * 10)
    await driver.start_read_transaction(addr=ADDRESS, length=DATA_COUNT, user_id=0)
    await Timer(CLK_PERIOD * 10)
    cocotb.start_soon(axis_sink.receive())
    await Timer(CLK_PERIOD * 50)

    if await driver.is_ready():
        dut._log.warning ("Ready ***********************")
    else:
        dut._log.warning ("NOT Ready &&&&&&&&&&&&&&&&")

    rdata = axis_sink.read_data()

