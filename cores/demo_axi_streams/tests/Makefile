
TOPLEVEL_LANG ?= verilog

ifneq ($(TOPLEVEL_LANG),verilog)
all:
	@echo "Skipping; this example does not support VHDL at the top-level"
clean::

else

PWD=$(shell pwd)
TOPDIR=$(PWD)/..
PYTHONPATH := ./model:$(PYTHONPATH)

export PYTHONPATH

SIM ?= icarus

#not sure if only icarus include is by -I ...
ifeq ($(SIM),icarus)
COMPILE_ARGS+=-I$(TOPDIR)/hdl/
else
COMPILE_ARGS+=+incdir+$(TOPDIR)/hdl/
endif

#DUT
VERILOG_SOURCES = $(TOPDIR)/hdl/axi_lite_slave.v
VERILOG_SOURCES += $(TOPDIR)/hdl/axis_2_fifo_adapter.v
VERILOG_SOURCES += $(TOPDIR)/hdl/fifo.v
VERILOG_SOURCES += $(TOPDIR)/hdl/fifo_2_axis_adapter.v
VERILOG_SOURCES += $(TOPDIR)/hdl/demo_axi_streams.v

#Test Bench
VERILOG_SOURCES += $(TOPDIR)/tests/tb_axi_lite_slave.v

TOPLEVEL = tb_axi_lite_slave

GPI_IMPL := vpi

export TOPLEVEL_LANG
MODULE=test_dut

include $(shell cocotb-config --makefiles)/Makefile.sim

endif

.PHONY: wave wave1
wave:
	gtkwave waveforms.gtkw &

wave1:
	gtkwave design.vcd &


