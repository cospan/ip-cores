set project_name fps_counter_project
set top_name fps_counter
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




