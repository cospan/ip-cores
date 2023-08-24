# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIS_DATA_USER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIS_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "AXIS_KEEP_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CLOCK_FREQUENCY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FPS_COUNT_MAX" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IMG_HEIGHT_MAX" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IMG_WIDTH_MAX" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INVERT_AXI_RESET" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIS_DATA_USER_WIDTH { PARAM_VALUE.AXIS_DATA_USER_WIDTH } {
	# Procedure called to update AXIS_DATA_USER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_DATA_USER_WIDTH { PARAM_VALUE.AXIS_DATA_USER_WIDTH } {
	# Procedure called to validate AXIS_DATA_USER_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIS_DATA_WIDTH { PARAM_VALUE.AXIS_DATA_WIDTH } {
	# Procedure called to update AXIS_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_DATA_WIDTH { PARAM_VALUE.AXIS_DATA_WIDTH } {
	# Procedure called to validate AXIS_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIS_KEEP_WIDTH { PARAM_VALUE.AXIS_KEEP_WIDTH } {
	# Procedure called to update AXIS_KEEP_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_KEEP_WIDTH { PARAM_VALUE.AXIS_KEEP_WIDTH } {
	# Procedure called to validate AXIS_KEEP_WIDTH
	return true
}

proc update_PARAM_VALUE.CLOCK_FREQUENCY { PARAM_VALUE.CLOCK_FREQUENCY } {
	# Procedure called to update CLOCK_FREQUENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLOCK_FREQUENCY { PARAM_VALUE.CLOCK_FREQUENCY } {
	# Procedure called to validate CLOCK_FREQUENCY
	return true
}

proc update_PARAM_VALUE.FPS_COUNT_MAX { PARAM_VALUE.FPS_COUNT_MAX } {
	# Procedure called to update FPS_COUNT_MAX when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FPS_COUNT_MAX { PARAM_VALUE.FPS_COUNT_MAX } {
	# Procedure called to validate FPS_COUNT_MAX
	return true
}

proc update_PARAM_VALUE.IMG_HEIGHT_MAX { PARAM_VALUE.IMG_HEIGHT_MAX } {
	# Procedure called to update IMG_HEIGHT_MAX when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMG_HEIGHT_MAX { PARAM_VALUE.IMG_HEIGHT_MAX } {
	# Procedure called to validate IMG_HEIGHT_MAX
	return true
}

proc update_PARAM_VALUE.IMG_WIDTH_MAX { PARAM_VALUE.IMG_WIDTH_MAX } {
	# Procedure called to update IMG_WIDTH_MAX when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMG_WIDTH_MAX { PARAM_VALUE.IMG_WIDTH_MAX } {
	# Procedure called to validate IMG_WIDTH_MAX
	return true
}

proc update_PARAM_VALUE.INVERT_AXI_RESET { PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to update INVERT_AXI_RESET when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INVERT_AXI_RESET { PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to validate INVERT_AXI_RESET
	return true
}


proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.CLOCK_FREQUENCY { MODELPARAM_VALUE.CLOCK_FREQUENCY PARAM_VALUE.CLOCK_FREQUENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLOCK_FREQUENCY}] ${MODELPARAM_VALUE.CLOCK_FREQUENCY}
}

proc update_MODELPARAM_VALUE.IMG_WIDTH_MAX { MODELPARAM_VALUE.IMG_WIDTH_MAX PARAM_VALUE.IMG_WIDTH_MAX } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMG_WIDTH_MAX}] ${MODELPARAM_VALUE.IMG_WIDTH_MAX}
}

proc update_MODELPARAM_VALUE.IMG_HEIGHT_MAX { MODELPARAM_VALUE.IMG_HEIGHT_MAX PARAM_VALUE.IMG_HEIGHT_MAX } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMG_HEIGHT_MAX}] ${MODELPARAM_VALUE.IMG_HEIGHT_MAX}
}

proc update_MODELPARAM_VALUE.FPS_COUNT_MAX { MODELPARAM_VALUE.FPS_COUNT_MAX PARAM_VALUE.FPS_COUNT_MAX } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FPS_COUNT_MAX}] ${MODELPARAM_VALUE.FPS_COUNT_MAX}
}

proc update_MODELPARAM_VALUE.AXIS_DATA_WIDTH { MODELPARAM_VALUE.AXIS_DATA_WIDTH PARAM_VALUE.AXIS_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_DATA_WIDTH}] ${MODELPARAM_VALUE.AXIS_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.AXIS_KEEP_WIDTH { MODELPARAM_VALUE.AXIS_KEEP_WIDTH PARAM_VALUE.AXIS_KEEP_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_KEEP_WIDTH}] ${MODELPARAM_VALUE.AXIS_KEEP_WIDTH}
}

proc update_MODELPARAM_VALUE.AXIS_DATA_USER_WIDTH { MODELPARAM_VALUE.AXIS_DATA_USER_WIDTH PARAM_VALUE.AXIS_DATA_USER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_DATA_USER_WIDTH}] ${MODELPARAM_VALUE.AXIS_DATA_USER_WIDTH}
}

proc update_MODELPARAM_VALUE.INVERT_AXI_RESET { MODELPARAM_VALUE.INVERT_AXI_RESET PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVERT_AXI_RESET}] ${MODELPARAM_VALUE.INVERT_AXI_RESET}
}

