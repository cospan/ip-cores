

__author__ = "<your@email.here>"

from axi_driver import Driver



REG_CONTROL       = 0 << 2
REG_CLK_DIV       = 1 << 2
REG_RGB0_COLOR    = 2 << 2
REG_RGB1_COLOR    = 3 << 2
REG_ST_CTRL       = 4 << 2
REG_ST_COUNT      = 5 << 2
REG_ST_PWM_LEN    = 6 << 2
REG_ST_TRANS_LEN  = 7 << 2
REG_VERSION       = 8 << 2

#Set/Clear a bit
BIT_CTRL_EN             = 0
BIT_CTRL_AUTO           = 1

#Set/Get a range of bits
BIT_CTRL_TR_HIGH        = 15
BIT_CTRL_TR_LOW         = 8

class LightshowDriver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(LightshowDriver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

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

    # Set a bit within a register
    async def enable_rgb(self, enable):
        await self.enable_register_bit(REG_CONTROL, BIT_CTRL_EN, enable)

    # Set a bit within a register
    async def enable_auto(self, enable):
        await self.enable_register_bit(REG_CONTROL, BIT_CTRL_AUTO, enable)

    # Set an entire Register
    async def set_state_pwm_length(self, data):
        await self.write_register(REG_ST_PWM_LEN, data)

    # Set an entire Register
    async def set_state_transition_length(self, data):
        await self.write_register(REG_ST_TRANS_LEN, data)


    # Set an entire Register
    async def set_state_color(self, index, color):
        data = 0x00
        data |= index << 24
        data |= color
        await self.write_register(REG_ST_CTRL, data)

    # Set an entire Register
    async def set_state_count(self, count):
        await self.write_register(REG_ST_COUNT, count)

    # Set Color
    async def set_manual_color(self, color):
        await self.write_register(REG_RGB0_COLOR, color)






    # Read a single bit within a register
    async def is_test_mode(self):
        bit_val = await self.is_register_bit_set(REG_CONTROL, BIT_CTRL_EN)
        return bit_val

    # Set a range of data withing a register
    async def set_control_test_range(self, data):
        await self.write_register_bit_range(REG_CONTROL, BIT_CTRL_TR_HIGH, BIT_CTRL_TR_LOW, data)

    # Get a range of data within a register
    async def get_control_test_range(self, data):
        data = await self.read_register_bit_range(REG_CONTROL, BIT_CTRL_TR_HIGH, BIT_CTRL_TR_LOW, data)
        return data

