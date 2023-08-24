

__author__ = "<your@email.here>"

from axi_driver import Driver

REG_CONTROL             = 0  << 2
REG_DEMO                = 1  << 2
REG_VERSION             = 2  << 2

#Set/Clear a bit
BIT_CTRL_TEST           = 0

#Set/Get a range of bits
BIT_CTRL_TR_HIGH        = 15
BIT_CTRL_TR_LOW         = 8

class demo_part2Driver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(demo_part2Driver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

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

    # Set an entire Register
    async def set_demo(self, data):
        await self.write_register(REG_DEMO, data)

    # Get Entire Register
    async def get_demo(self):
        data = await self.read_register(REG_DEMO)
        return data

    # Set a bit within a register
    async def enable_test_mode(self, enable):
        await self.enable_register_bit(REG_CONTROL, BIT_CTRL_TEST, enable)

    # Read a single bit within a register
    async def is_test_mode(self):
        bit_val = await self.is_register_bit_set(REG_CONTROL, BIT_CTRL_TEST)
        return bit_val

    # Set a range of data withing a register
    async def set_control_test_range(self, data):
        await self.write_register_bit_range(REG_CONTROL, BIT_CTRL_TR_HIGH, BIT_CTRL_TR_LOW, data)

    # Get a range of data within a register
    async def get_control_test_range(self, data):
        data = await self.read_register_bit_range(REG_CONTROL, BIT_CTRL_TR_HIGH, BIT_CTRL_TR_LOW, data)
        return data

