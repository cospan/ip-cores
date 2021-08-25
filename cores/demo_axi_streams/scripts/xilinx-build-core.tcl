set project_name demo_axi_streams_project
set top_name demo_axi_streams
#set device DEFAULT_DEVICE
#If nothing is set build for pynq-z2
set device xc7z020clg400-1

#set project_dir [file normalize [file join [file dirname [info script]] ".." ]]
set project_dir [file join [file dirname [info script]] ".." ]
set source_dir $project_dir

proc findVerilogFiles { dir } {
	set vSources [list]
	set contents [glob -nocomplain -directory $dir *]

	foreach item $contents {
		#puts $item
		# recurse - go into the sub directory
		if { [file isdirectory $item] } {
			set innerItems [findVerilogFiles $item]
			foreach f $innerItems {
				#set lf = [file normalize $f]
				#lappend vSources $lf
				lappend vSources $f
			}
		} elseif {[regexp {\.v$} $item]} {
			#puts $item
			lappend vSources $item
		}
	}
	return $vSources
}

#Create the project in the current directory
create_project $project_name $project_name -part $device -force
set_property design_mode RTL [get_filesets sources_1]

# How to handle the generics??, could either copy it all in or make a link back to the repo, perhaps leave it to the user with the default behavior is to copy all of the generics
set verilog_sources [findVerilogFiles $source_dir/hdl]

#XXX: How to add the generics?
#		Can copy the files from the main repo to the user project

# Import the individual files into the project
#add_files -fileset [get_filesets sources_1] -force -norecurse $verilog_sources -relative_to [file normalize $source_dir/hdl]
add_files -fileset [get_filesets sources_1] -force -norecurse $verilog_sources

# Generate Package
ipx::package_project -root_dir /home/cospan/Projects/ip-cores/cores/demo_axi_streams -vendor user.org -library user -taxonomy /UserIP

# Control Bus

ipx::add_bus_interface ctrl [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_READ_OUTSTANDING [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_WRITE_OUTSTANDING [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
ipx::add_port_map RREADY [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_rready [ipx::get_port_maps RREADY -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map BREADY [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_bready [ipx::get_port_maps BREADY -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map AWVALID [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_awvalid [ipx::get_port_maps AWVALID -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map WDATA [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_wdata [ipx::get_port_maps WDATA -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map ARADDR [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_araddr [ipx::get_port_maps ARADDR -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map AWADDR [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_awaddr [ipx::get_port_maps AWADDR -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map WVALID [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_wvalid [ipx::get_port_maps WVALID -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map ARVALID [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name i_arvalid [ipx::get_port_maps ARVALID -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
set_property display_name Control [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
ipx::add_port_map BVALID [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_bvalid [ipx::get_port_maps BVALID -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map AWREADY [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_awready [ipx::get_port_maps AWREADY -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map RRESP [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_rresp [ipx::get_port_maps RRESP -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map RVALID [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_rvalid [ipx::get_port_maps RVALID -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map ARREADY [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_arready [ipx::get_port_maps ARREADY -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map WREADY [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_wready [ipx::get_port_maps WREADY -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map BRESP [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_bresp [ipx::get_port_maps BRESP -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]
ipx::add_port_map RDATA [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
set_property physical_name o_rdata [ipx::get_port_maps RDATA -of_objects [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]]

ipx::associate_bus_interfaces -busif ctrl -clock i_axi_clk [ipx::current_core]

# Create the address Map
ipx::add_memory_map ctrl [ipx::current_core]
set_property slave_memory_map_ref ctrl [ipx::get_bus_interfaces ctrl -of_objects [ipx::current_core]]
ipx::add_address_block main [ipx::get_memory_maps ctrl -of_objects [ipx::current_core]]

# Configure the GUI
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "FIFO_DATA_WIDTH" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "AXIS_KEEP_WIDTH" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]
set_property display_name {Configuration} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]
set_property tooltip {Configure Main AXI Lite Control/AXI Stream/FIFO} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]
ipgui::add_group -name {AXI Control Config} -component [ipx::current_core] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ] -display_name {AXI Control Config}
ipgui::add_group -name {AXI Stream Config} -component [ipx::current_core] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ] -display_name {AXI Stream Config}
ipgui::add_group -name {FIFO Config} -component [ipx::current_core] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ] -display_name {FIFO Config}
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Control Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Control Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "AXIS_DATA_USER_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Stream Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "AXIS_DATA_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Stream Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "INVERT_AXIS_RESET" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Stream Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "INVERT_AXIS_RESET" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Stream Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "INVERT_AXI_RESET" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Control Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 1 [ipgui::get_guiparamspec -name "ADDR_WIDTH" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "AXI Control Config" -component [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "FIFO_DEPTH" -component [ipx::current_core]] -parent [ipgui::get_groupspec -name "FIFO Config" -component [ipx::current_core]]
ipgui::remove_param -component [ipx::current_core] [ipgui::get_guiparamspec -name "DATA_WIDTH" -component [ipx::current_core]]

ipx::remove_bus_interface i_axis_in [ipx::current_core]
ipx::remove_bus_interface o_axis_out [ipx::current_core]

ipx::add_bus_interface axis_in [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
ipx::add_port_map TUSER [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
set_property physical_name i_axis_in_tuser [ipx::get_port_maps TUSER -of_objects [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
set_property physical_name i_axis_in_tdata [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
set_property physical_name i_axis_in_tvalid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
set_property physical_name i_axis_in_tlast [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]
set_property physical_name o_axis_in_tready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces axis_in -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif axis_in -clock i_axis_clk [ipx::current_core]


ipx::add_bus_interface axis_out [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0 [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0 [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
ipx::add_port_map TUSER [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property physical_name o_axis_out_tuser [ipx::get_port_maps TUSER -of_objects [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]]
ipx::add_port_map TVALID [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property physical_name o_axis_out_tvalid [ipx::get_port_maps TVALID -of_objects [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]]
ipx::add_port_map TLAST [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property physical_name o_axis_out_tlast [ipx::get_port_maps TLAST -of_objects [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]]
ipx::add_port_map TDATA [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property physical_name o_axis_out_tdata [ipx::get_port_maps TDATA -of_objects [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]]
ipx::add_port_map TREADY [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]
set_property physical_name i_axis_out_tready [ipx::get_port_maps TREADY -of_objects [ipx::get_bus_interfaces axis_out -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif axis_out -clock i_axis_clk [ipx::current_core]

# Package the IP
set_property core_revision 3 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog -rebuild -repo_path /home/cospan/Projects/ip-cores/cores/demo_axi_streams
