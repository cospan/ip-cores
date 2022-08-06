__author__ = "<your@email.here>"

from axi_driver import Driver

REG_CONTROL     = 0  << 2
REG_STATUS      = 1  << 2
REG_ADDR        = 2  << 2
REG_DATA_LEN    = 3  << 2
REG_VERSION     = 4  << 2

#Set/Get a range of bits

BIT_CTRL_READ_START     =  0
BIT_CTRL_WRITE_START    =  1
BIT_STS_READY           =  0
#BITRANGE_ID             =  (31, 16)
BITRANGE_ID_HIGH        = 31
BITRANGE_ID_LOW         = 16



class AXIMasterTesterDriver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(AXIMasterTesterDriver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

    def __del__(self):
        pass

    async def get_version(self):
        data = await self.read_register(REG_VERSION)
        return data

    # Set the control register
    async def set_control(self, data):
        await self.write_register(REG_CONTROL, data)

    # Get Entire Register
    async def get_control(self):
        data = await self.read_register(REG_CONTROL)
        return data

    # Demonstrate enabling an individual bit within a register
    async def start_write_transaction(self, addr, length, user_id=0):
        await self.write_register(REG_ADDR, addr)
        await self.write_register(REG_DATA_LEN, length)
        await self.write_register_bit_range(REG_CONTROL, BITRANGE_ID_HIGH, BITRANGE_ID_LOW, user_id) 
        await self.set_register_bit(REG_CONTROL, BIT_CTRL_WRITE_START)

    # Demonstrate enabling an individual bit within a register
    async def start_read_transaction(self, addr, length, user_id=0):
        await self.write_register(REG_ADDR, addr)
        await self.write_register(REG_DATA_LEN, length)
        await self.write_register_bit_range(REG_CONTROL, BITRANGE_ID_HIGH, BITRANGE_ID_LOW, user_id) 
        await self.set_register_bit(REG_CONTROL, BIT_CTRL_READ_START)

    # Read a single bit within a register
    async def is_ready(self):
        bit_val = await self.is_register_bit_set(REG_STATUS, BIT_STS_READY)
        return bit_val

    async def get_resp_id(self):
        resp_id = await self.read_register_bit_range(REG_STATUS, BITRANGE_ID_HIGH, BITRANGE_ID_LOW)
        return resp_id

    ## Set a range of data withing a register
    #async def set_control_test_range(self, data):
    #    await self.write_register_bit_range(REG_CONTROL, BIT_CTRL_TR_HIGH, BIT_CTRL_TR_LOW, data)

    ## Get a range of data within a register
    #async def get_control_test_range(self, data):
    #    data = await self.read_register_bit_range(REG_CONTROL, BIT_CTRL_TR_HIGH, BIT_CTRL_TR_LOW, data)
    #    return data

