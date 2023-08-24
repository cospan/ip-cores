

__author__ = "<your@email.here>"

from axi_driver import Driver


REG_CONTROL         = 0 << 2
REG_STATUS          = 1 << 2
REG_CLOCK_RATE      = 2 << 2
REG_CLOCK_DIVIDER   = 3 << 2
REG_AUDIO_RATE      = 4 << 2
REG_AUDIO_BITS      = 5 << 2
REG_AUDIO_CHANNELS  = 6 << 2
REG_VERSION         = 7 << 2



CTL_BIT_ENABLE              =  0
CTL_BIT_ENABLE_WAVE         =  1
CTL_BIT_ENABLE_INTERRUPT    =  2
CTL_BIT_WAVE_SEL            =  3



class axi_i2sDriver (Driver):
    def __init__(self, dut, clock, reset, clk_period, name="aximl", debug = False):
        super(axi_i2sDriver, self).__init__(dut, clock, reset, clk_period, name, debug=debug)

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
    async def enable_audio_fifo(self, enable):
        await self.enable_register_bit(REG_CONTROL, CTL_BIT_ENABLE, enable)

    # Read a single bit within a register
    async def is_audio_wave_enabled(self):
        bit_val = await self.is_register_bit_set(REG_CONTROL, CTL_BIT_ENABLE)
        return bit_val



    # Demonstrate enabling an individual bit within a register
    async def enable_wave(self, enable):
        await self.enable_register_bit(REG_CONTROL, CTL_BIT_ENABLE_WAVE, enable)

    # Read a single bit within a register
    async def is_audio_wave_enabled(self):
        bit_val = await self.is_register_bit_set(REG_CONTROL, CTL_BIT_ENABLE_WAVE)
        return bit_val




    # Demonstrate enabling an individual bit within a register
    async def select_triangle_or_sine_wave(self, wave):
        await self.enable_register_bit(REG_CONTROL, CTL_BIT_WAVE_SEL, wave)

    # Read a single bit within a register
    async def is_triangle_or_sine_wave(self):
        bit_val = await self.is_register_bit_set(REG_CONTROL, CTL_BIT_WAVE_SEL)
        return bit_val







