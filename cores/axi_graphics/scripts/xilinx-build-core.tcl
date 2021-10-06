set project_name axi_graphics_project
set top_name axi_graphics
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

#ipx::package_project -root_dir [file normalize $project_dir/$project_name] -vendor user.org -library user -taxonomy /UserIP
ipx::package_project -root_dir $project_dir/$project_name -vendor user.org -library user -taxonomy /UserIP

ipx::add_bus_interface control [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property display_name Control [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property description {AXI Lite Slave Interface} [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_READ_OUTSTANDING [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_WRITE_OUTSTANDING [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
ipx::add_port_map BVALID [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_bvalid [ipx::get_port_maps BVALID -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map RREADY [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_rready [ipx::get_port_maps RREADY -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map BREADY [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_bready [ipx::get_port_maps BREADY -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map AWVALID [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_awvalid [ipx::get_port_maps AWVALID -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map AWREADY [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_awready [ipx::get_port_maps AWREADY -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map WDATA [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_wdata [ipx::get_port_maps WDATA -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map RRESP [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_rresp [ipx::get_port_maps RRESP -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map RVALID [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_rvalid [ipx::get_port_maps RVALID -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map ARADDR [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_araddr [ipx::get_port_maps ARADDR -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map AWADDR [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_awaddr [ipx::get_port_maps AWADDR -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map ARREADY [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_arready [ipx::get_port_maps ARREADY -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map WVALID [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_wvalid [ipx::get_port_maps WVALID -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map WREADY [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_wready [ipx::get_port_maps WREADY -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map ARVALID [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_arvalid [ipx::get_port_maps ARVALID -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map WSTRB [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name i_wstrb [ipx::get_port_maps WSTRB -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map BRESP [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_bresp [ipx::get_port_maps BRESP -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]
ipx::add_port_map RDATA [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
set_property physical_name o_rdata [ipx::get_port_maps RDATA -of_objects [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]]

# Associate the clock with the above bus
ipx::associate_bus_interfaces -busif control -clock i_axi_clk [ipx::current_core]
ipx::associate_bus_interfaces -clock i_axi_clk -reset i_axi_rst -remove [ipx::current_core]
ipx::remove_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces i_axi_clk -of_objects [ipx::current_core]]

# Add an address map
ipx::add_memory_map control [ipx::current_core]
set_property slave_memory_map_ref control [ipx::get_bus_interfaces control -of_objects [ipx::current_core]]
ipx::add_address_block main [ipx::get_memory_maps control -of_objects [ipx::current_core]]


#Generate the core
# Update the revision
set cv [get_property core_revision [ipx::current_core]]
set cv [expr {$cv + 1}]
set_property core_revision $cv [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  $project_dir/$project_name [current_project]
update_ip_catalog
