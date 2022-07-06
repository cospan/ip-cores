

__author__ = "<your@email.here>"

from axi_driver import Driver


REG_CONTROL             = 0 << 2;
REG_STATUS              = 1 << 2;
REG_CLK_PERIOD          = 2 << 2;
REG_TOTAL_FRAMES        = 3 << 2;
REG_FRAMES_PER_SECOND   = 4 << 2;
REG_LINES_PER_FRAME     = 5 << 2;
REG_PIXELS_PER_ROW      = 6 << 2;
REG_VERSION             = 7 << 2;

#Set/Clear a bit
BIT_CTRL_RESET_FRAME_COUNTS     = 0

BIT_STS_FRAME_DETECTED          = 0
BIT_STS_ROWS_NOT_EQUAL          = 1
BIT_STS_LINES_NOT_EQUAL         = 2

class FPSCounterDriver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(FPSCounterDriver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

    def __del__(self):
        pass

    async def get_version(self):
        data = await self.read_register(REG_VERSION)
        return data

    async def are_rows_equal(self):
        data = await self.is_register_bit_set(REG_STATUS, BIT_STS_ROWS_NOT_EQUAL)
        await self.set_register_bit(REG_STATUS, BIT_STS_ROWS_NOT_EQUAL)
        return data

    async def are_lines_equal(self):
        data = await self.is_register_bit_set(REG_STATUS, BIT_STS_LINES_NOT_EQUAL)
        await self.set_register_bit(REG_STATUS, BIT_STS_LINES_NOT_EQUAL)
        return data

    async def is_frame_detected(self):
        data = await self.is_register_bit_set(REG_STATUS, BIT_STS_FRAME_DETECTED)
        await self.set_register_bit(REG_STATUS, BIT_STS_FRAME_DETECTED)
        return data

    async def set_clock_period(self, period):
        await self.write_register(REG_CLK_PERIOD, period)

    async def reset_frame_counts(self, enable):
        await self.enable_register_bit(REG_CONTROL, BIT_CTRL_RESET_FRAME_COUNTS, enable)

    async def get_total_frames(self):
        data = await self.read_register(REG_TOTAL_FRAMES)
        return data

    async def get_frames_per_second(self):
        data = await self.read_register(REG_FRAMES_PER_SECOND)
        return data

    async def get_lines_per_frame(self):
        data = await self.read_register(REG_LINES_PER_FRAME)
        return data

    async def get_pixels_per_row(self):
        data = await self.read_register(REG_PIXELS_PER_ROW)
        return data

