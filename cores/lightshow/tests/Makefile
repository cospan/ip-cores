
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
COMPILE_ARGS+=-I$(TOPDIR)/hdl/ -DSIM_DEBUG
else
COMPILE_ARGS+=+incdir+$(TOPDIR)/hdl/ -DSIM_DEBUG
endif

#DUT
VERILOG_SOURCES = $(TOPDIR)/hdl/axi_lite_slave.v
VERILOG_SOURCES += $(TOPDIR)/hdl/lightshow.v
VERILOG_SOURCES += $(TOPDIR)/hdl/rgb_led_control.v

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


