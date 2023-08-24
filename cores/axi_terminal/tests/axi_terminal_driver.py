

__author__ = "<cospan@gmail.com>"

from axi_driver import Driver


REG_CONTROL         = 0  << 2;
REG_STATUS          = 1  << 2;
REG_IMAGE_WIDTH     = 2  << 2;
REG_IMAGE_HEIGHT    = 3  << 2;
REG_IMAGE_SIZE      = 4  << 2;
REG_FG_COLOR        = 5  << 2;
REG_BG_COLOR        = 6  << 2;
REG_CONSOLE_CHAR    = 7  << 2;
REG_CONSOLE_COMMAND = 8  << 2;
REG_TAB_COUNT       = 9  << 2;
REG_X_START         = 10 << 2;
REG_X_END           = 11 << 2;
REG_Y_START         = 12 << 2;
REG_Y_END           = 13 << 2;
REG_ADAPTER_DEBUG   = 14 << 2;
REG_ALPHA           = 15 << 2;
REG_INTERVAL        = 16 << 2;
REG_VERSION         = 20 << 2;


BIT_CTRL_EN               = 0
BIT_CTRL_CLEAR_SCREEN_STB = 1
BIT_CTRL_SCROLL_EN        = 4
BIT_CTRL_SCROLL_UP_STB    = 5
BIT_CTRL_SCROLL_DOWN_STB  = 6


class AxiTerminalDriver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(AxiTerminalDriver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

    def __del__(self):
        pass

    async def enable_terminal(self, enable):
        await self.enable_register_bit(REG_CONTROL, BIT_CTRL_EN, enable)

    async def is_terminal_enabled(self):
        data = await self.is_register_bit_set(REG_CONTROL, BIT_CTRL_EN)
        return data

    async def get_version(self):
        data = await self.read_register(REG_VERSION)
        return data

    async def clear_screen(self):
        await self.set_register_bit(REG_CONTROL, BIT_CTRL_SCREEN_STB);

    async def get_video_width(self):
        data = await self.read_register(REG_IMAGE_WIDTH)
        return data

    async def get_video_height(self):
        data = await self.read_register(REG_IMAGE_HEIGHT)
        return data

    async def write_string(self, data):
        for c in data:
            await put_char(c)

    async def put_char(self, c):
        await self.write_register(REG_CONSOLE_CHAR, ord(c))

    async def put_raw_char(self, c):
        await self.write_register(REG_CONSOLE_CHAR, c)

    async def set_background_color(self, color):
        await self.write_register(REG_BG_COLOR, color)

    async def set_alpha(self, alpha):
        await self.write_register(REG_ALPHA, alpha)

    async def dump_registers(self):
        for i in range(REG_VERISON + 1):
            data = await self.read_register(i)
            print ("0x%08X: 0x%08X", i, data)

    async def image_adjust_padding(self):
        width  = await self.get_video_width()
        height = await self.get_video_height()
        #XXX: Need way toget font width/height from core
        font_width = 6
        font_height = 8
        #Get padding:
        true_width  = (width  // font_width)  * font_width
        true_height = (height // font_height) * font_height
        await self.write_register(REG_X_END, true_width)
        await self.write_register(REG_Y_END, true_height)

