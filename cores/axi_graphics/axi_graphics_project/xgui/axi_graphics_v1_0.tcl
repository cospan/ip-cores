# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIS_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "HEIGHT_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INTERVAL_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INVERT_AXI_RESET" -parent ${Page_0}
  ipgui::add_param $IPINST -name "WIDTH_SIZE" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIS_DATA_WIDTH { PARAM_VALUE.AXIS_DATA_WIDTH } {
	# Procedure called to update AXIS_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_DATA_WIDTH { PARAM_VALUE.AXIS_DATA_WIDTH } {
	# Procedure called to validate AXIS_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.HEIGHT_SIZE { PARAM_VALUE.HEIGHT_SIZE } {
	# Procedure called to update HEIGHT_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.HEIGHT_SIZE { PARAM_VALUE.HEIGHT_SIZE } {
	# Procedure called to validate HEIGHT_SIZE
	return true
}

proc update_PARAM_VALUE.INTERVAL_SIZE { PARAM_VALUE.INTERVAL_SIZE } {
	# Procedure called to update INTERVAL_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INTERVAL_SIZE { PARAM_VALUE.INTERVAL_SIZE } {
	# Procedure called to validate INTERVAL_SIZE
	return true
}

proc update_PARAM_VALUE.INVERT_AXI_RESET { PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to update INVERT_AXI_RESET when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INVERT_AXI_RESET { PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to validate INVERT_AXI_RESET
	return true
}

proc update_PARAM_VALUE.WIDTH_SIZE { PARAM_VALUE.WIDTH_SIZE } {
	# Procedure called to update WIDTH_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WIDTH_SIZE { PARAM_VALUE.WIDTH_SIZE } {
	# Procedure called to validate WIDTH_SIZE
	return true
}


proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.AXIS_DATA_WIDTH { MODELPARAM_VALUE.AXIS_DATA_WIDTH PARAM_VALUE.AXIS_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_DATA_WIDTH}] ${MODELPARAM_VALUE.AXIS_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.WIDTH_SIZE { MODELPARAM_VALUE.WIDTH_SIZE PARAM_VALUE.WIDTH_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WIDTH_SIZE}] ${MODELPARAM_VALUE.WIDTH_SIZE}
}

proc update_MODELPARAM_VALUE.HEIGHT_SIZE { MODELPARAM_VALUE.HEIGHT_SIZE PARAM_VALUE.HEIGHT_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.HEIGHT_SIZE}] ${MODELPARAM_VALUE.HEIGHT_SIZE}
}

proc update_MODELPARAM_VALUE.INTERVAL_SIZE { MODELPARAM_VALUE.INTERVAL_SIZE PARAM_VALUE.INTERVAL_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INTERVAL_SIZE}] ${MODELPARAM_VALUE.INTERVAL_SIZE}
}

proc update_MODELPARAM_VALUE.INVERT_AXI_RESET { MODELPARAM_VALUE.INVERT_AXI_RESET PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVERT_AXI_RESET}] ${MODELPARAM_VALUE.INVERT_AXI_RESET}
}

