# Create an AXI enabled repository



TL;DR version

* Install everyting (See Installation Section)
* Within the repo, run this script

```
./scripts/new-ip-core.sh demo
cd cores
./make xilinx_ip_no_gui
```

* Add this repo to a Vivado project, it will automatically find the core that was just created with the name 'demo'
* Find the core within the IP dictionary and drop it into the design
* Perform the normal auto IP connection wizards
* Verify the core is within the address space, if not assign it.


## Story

Many modern FPGA designs employ individual IP cores that are connected through the AXI bus protocol. The process of developing an AXI enabled core that can be used within an FPGA can be challenging, this repo aims to simplify that process.



Users can create a custom core by running a script, the script can then be used to generate a core that can be dropped into an FPGA project, and communicated with without modifying any code.

## Installation

Install the following packages

```
sudo apt install build-essential gtkwave iverilog
```

Install the repositories
```
pip3 install cocotb cocotb-bus cocotbext-axi pytest
```


# TODO

* [ ] Incorporate Generic Verilog Cores
* [ ] Zynq Interface
* [ ] Pynq Interface
* [ ] Micro-Blaze
* [ ] AXI Stream Input
* [ ] AXI Stream Output
* [ ] Talk about simulations
* [ ] What makes this different than the Xilinx provided AXI Interfaces
	* [ ] Easier to interface with the core
	* [ ] Simulations are simpler
	* [ ] Faster than Vivado GUI based solutions
* [ ] Conditional Build, Xilinx/Intel/Yosys


