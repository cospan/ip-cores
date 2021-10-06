from cocotb.triggers import Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

class Driver(object):

    def __init__(self, dut, clock, reset, clk_period, name="AXIML", debug=False):
        self.debug = debug
        self.dut = dut
        self.clock = clock
        self.clk_period = clk_period
        self.axim = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "aximl"), clock, reset)
        dut._log.debug ("Started")

    async def read_register(self, address):
        """read_register

        Reads a single register from the read command and then converts it to an
        integer

        Args:
          address (int):  Address of the register/memory to read

        Returns:
          (int): 32-bit unsigned register value
        """
        data = await self.axim.read(address, 4)
        return int.from_bytes(data.data, byteorder="little")

    async def write_register(self, address, value):
        """write_register

        Writes a single register from a 32-bit unsingned integer

        Args:
          address (int):  Address of the register/memory to read
          value (int)  32-bit unsigned integer to be written into the register

        Returns:
          Nothing
        """
        await self.axim.write(address, value.to_bytes(4, byteorder="little"))

    async def enable_register_bit(self, address, bit, enable):
        """enable_register_bit

        Pass a bool value to set/clear a bit

        Args:
          address (int): Address of the register/memory to modify
          bit (int): Address of bit to set (31 - 0)
          enable (bool): set or clear a bit

        Returns:
          Nothing
        """
        if enable:
            await self.set_register_bit(address, bit)
        else:
            await self.clear_register_bit(address, bit)

    async def set_register_bit(self, address, bit):
        """set_register_bit

        Sets an individual bit in a register

        Args:
          address (int): Address of the register/memory to modify
          bit (int): Address of bit to set (31 - 0)

        Returns:
          Nothing
        """
        register = await self.read_register(address)
        bit_mask =  1 << bit
        register |= bit_mask
        await self.write_register(address, register)

    async def clear_register_bit(self, address, bit):
        """clear_register_bit

        Clear an individual bit in a register

        Args:
          address (int): Address of the register/memory to modify
          bit (int): Address of bit to set (31 - 0)

        Returns:
          Nothing
        """
        register = await self.read_register(address)
        bit_mask =  1 << bit
        register &= ~bit_mask
        await self.write_register(address, register)

    async def is_register_bit_set(self, address, bit):
        """is_register_bit_set

        raise ReturnValues true if an individual bit is set, false if clear

        Args:
          address (int): Address of the register/memory to read
          bit (int): Address of bit to check (31 - 0)

        Returns:
          (boolean):
            True: bit is set
            False: bit is not set
        """
        register = await self.read_register(address)
        bit_mask =  1 << bit
        #raise ReturnValue ((register & bit_mask) > 0)
        return (register & bit_mask) > 0

    async def write_register_bit_range(self, address, high_bit, low_bit, value):
        """
        Write data to a range of bits within a register

        Register = [XXXXXXXXXXXXXXXXXXXXXXXH---LXXXX]

        Write to a range of bits within ia register

        Args:
            address (unsigned long): Address or the register/memory to write
            high_bit (int): the high bit of the bit range to edit
            low_bit (int): the low bit of the bit range to edit
            value (int): the value to write in the range

        Returns:
            Nothing
        """
        reg = self.read_register(address)
        bitmask = (((1 << (high_bit + 1))) - (1 << low_bit))
        reg &= ~(bitmask)
        reg |= value << low_bit
        self.write_register(address, reg)

    async def read_register_bit_range(self, address, high_bit, low_bit):
        """
        Read a range of bits within a register at address 'address'

        Register = [XXXXXXXXXXXXXXXXXXXXXXXH---LXXXX]

        Read the value within a register, the top bit is H and bottom is L

        Args:
            address (unsigned long): Address or the register/memory to read
            high_bit (int): the high bit of the bit range to read
            low_bit (int): the low bit of the bit range to read

        Returns (unsigned integer):
            Value within the bitfield

        """

        value = await self.read_register(address)
        bitmask = (((1 << (high_bit + 1))) - (1 << low_bit))
        value = value & bitmask
        value = value >> low_bit
        return value

    async def sleep(self, clock_count):
        await Timer(clock_count * self.clk_period)

