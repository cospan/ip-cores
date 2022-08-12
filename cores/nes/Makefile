.PHONY: xilinx_ip xilinx_ip_no_gui

xilinx_ip:
	vivado -source scripts/xilinx-build-core.tcl -nojournal -nolog

xilinx_ip_no_gui:
	vivado -mode batch -source scripts/xilinx-build-core.tcl -nojournal -nolog

clean:
	rm -r nes_project

