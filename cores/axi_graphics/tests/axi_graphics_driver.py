

__author__ = "dmccoy@mit.edu (Dave McCoy)"

from axi_driver import Driver



REG_CONTROL             =  0 << 2
REG_STATUS              =  1 << 2
REG_WIDTH               =  2 << 2
REG_HEIGHT              =  3 << 2
REG_INTERVAL            =  4 << 2
REG_MODE_SEL            =  5 << 2
REG_XY_REF0             =  6 << 2
REG_XY_REF1             =  7 << 2
REG_FG_COLOR_REF        =  8 << 2
REG_BG_COLOR_REF        =  9 << 2


REG_VERSION             =  20 << 2

BIT_CTRL_ENABLE         = 0

class AXIGraphicsDriver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(AXIGraphicsDriver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

    def __del__(self):
        pass

    async def get_version(self):
        data = await self.read_register(REG_VERSION)
        return data

    async def get_control(self):
        data = await self.read_register(REG_CONTROL)
        return data

    async def set_control(self, data):
        await self.write_register(REG_CONTROL, data)

    async def enable(self, enable):
        await self.enable_register_bit(REG_CONTROL, BIT_CTRL_ENABLE, enable)

    async def is_enable(self):
        data = await self.is_register_bit_set(REG_CONTROL, BIT_CTRL_ENABLE)
        return data

    async def get_status(self):
        data = await self.read_register(REG_STATUS)
        return data

    async def set_width(self, width):
        await self.write_register(REG_WIDTH, width)

    async def get_width(self):
        data = await self.read_register(REG_WIDTH)
        return data

    async def set_height(self, height):
        await self.write_register(REG_HEIGHT, height)

    async def get_height(self):
        data = await self.read_register(REG_HEIGHT)
        return data

    async def set_interval(self, interval):
        await self.write_register(REG_INTERVAL)

    async def get_interval(self):
        data = await self.read_register(REG_INTERVAL)
        return data

    async def set_mode(self, mode):
        await self.write_register(REG_MODE_SEL, mode)

    async def get_mode(self):
        data = await self.read_register(REG_MODE_SEL)
        return data

    async def set_ref0_xy(self, x, y):
        data = (y << 16) | (x << 0)
        await self.write_register(REG_XY_REF0, data)

    async def get_ref0_xy(self):
        data = await self.read_register(REG_XY_REF0)
        x = (data >>  0) & 0x0FFF
        y = (data >> 16) & 0x0FFF
        return (x, y)

    async def set_ref1_xy(self, x, y):
        data = (y << 16) | (x << 0)
        await self.write_register(REG_XY_REF1, data)

    async def get_ref1_xy(self):
        data = await self.read_register(REG_XY_REF1)
        x = (data >>  0) & 0x0FFF
        y = (data >> 16) & 0x0FFF
        return (x, y)

    async def set_fg_color(self, fg_color):
        await self.write_register(REG_FG_COLOR_REF, fg_color)

    async def get_fg_color(self):
        data = await self.read_register(REG_FG_COLOR_REF)
        return data

    async def set_bg_color(self, bg_color):
        await self.write_register(REG_BG_COLOR_REF, bg_color)

    async def get_bg_color(self):
        data = await self.read_register(REG_BG_COLOR_REF)
        return data





