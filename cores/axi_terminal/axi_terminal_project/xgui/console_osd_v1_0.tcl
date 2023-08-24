# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BUFFER_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CONSOLE_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FONT_FILE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FONT_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FONT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IMAGE_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IMAGE_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IMAGE_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PIXEL_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.BUFFER_DEPTH { PARAM_VALUE.BUFFER_DEPTH } {
	# Procedure called to update BUFFER_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BUFFER_DEPTH { PARAM_VALUE.BUFFER_DEPTH } {
	# Procedure called to validate BUFFER_DEPTH
	return true
}

proc update_PARAM_VALUE.CONSOLE_DEPTH { PARAM_VALUE.CONSOLE_DEPTH } {
	# Procedure called to update CONSOLE_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONSOLE_DEPTH { PARAM_VALUE.CONSOLE_DEPTH } {
	# Procedure called to validate CONSOLE_DEPTH
	return true
}

proc update_PARAM_VALUE.FONT_FILE { PARAM_VALUE.FONT_FILE } {
	# Procedure called to update FONT_FILE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FONT_FILE { PARAM_VALUE.FONT_FILE } {
	# Procedure called to validate FONT_FILE
	return true
}

proc update_PARAM_VALUE.FONT_HEIGHT { PARAM_VALUE.FONT_HEIGHT } {
	# Procedure called to update FONT_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FONT_HEIGHT { PARAM_VALUE.FONT_HEIGHT } {
	# Procedure called to validate FONT_HEIGHT
	return true
}

proc update_PARAM_VALUE.FONT_WIDTH { PARAM_VALUE.FONT_WIDTH } {
	# Procedure called to update FONT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FONT_WIDTH { PARAM_VALUE.FONT_WIDTH } {
	# Procedure called to validate FONT_WIDTH
	return true
}

proc update_PARAM_VALUE.IMAGE_HEIGHT { PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to update IMAGE_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMAGE_HEIGHT { PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to validate IMAGE_HEIGHT
	return true
}

proc update_PARAM_VALUE.IMAGE_SIZE { PARAM_VALUE.IMAGE_SIZE } {
	# Procedure called to update IMAGE_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMAGE_SIZE { PARAM_VALUE.IMAGE_SIZE } {
	# Procedure called to validate IMAGE_SIZE
	return true
}

proc update_PARAM_VALUE.IMAGE_WIDTH { PARAM_VALUE.IMAGE_WIDTH } {
	# Procedure called to update IMAGE_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMAGE_WIDTH { PARAM_VALUE.IMAGE_WIDTH } {
	# Procedure called to validate IMAGE_WIDTH
	return true
}

proc update_PARAM_VALUE.PIXEL_WIDTH { PARAM_VALUE.PIXEL_WIDTH } {
	# Procedure called to update PIXEL_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PIXEL_WIDTH { PARAM_VALUE.PIXEL_WIDTH } {
	# Procedure called to validate PIXEL_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.CONSOLE_DEPTH { MODELPARAM_VALUE.CONSOLE_DEPTH PARAM_VALUE.CONSOLE_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CONSOLE_DEPTH}] ${MODELPARAM_VALUE.CONSOLE_DEPTH}
}

proc update_MODELPARAM_VALUE.IMAGE_WIDTH { MODELPARAM_VALUE.IMAGE_WIDTH PARAM_VALUE.IMAGE_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMAGE_WIDTH}] ${MODELPARAM_VALUE.IMAGE_WIDTH}
}

proc update_MODELPARAM_VALUE.IMAGE_HEIGHT { MODELPARAM_VALUE.IMAGE_HEIGHT PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMAGE_HEIGHT}] ${MODELPARAM_VALUE.IMAGE_HEIGHT}
}

proc update_MODELPARAM_VALUE.IMAGE_SIZE { MODELPARAM_VALUE.IMAGE_SIZE PARAM_VALUE.IMAGE_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMAGE_SIZE}] ${MODELPARAM_VALUE.IMAGE_SIZE}
}

proc update_MODELPARAM_VALUE.BUFFER_DEPTH { MODELPARAM_VALUE.BUFFER_DEPTH PARAM_VALUE.BUFFER_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BUFFER_DEPTH}] ${MODELPARAM_VALUE.BUFFER_DEPTH}
}

proc update_MODELPARAM_VALUE.PIXEL_WIDTH { MODELPARAM_VALUE.PIXEL_WIDTH PARAM_VALUE.PIXEL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PIXEL_WIDTH}] ${MODELPARAM_VALUE.PIXEL_WIDTH}
}

proc update_MODELPARAM_VALUE.FONT_FILE { MODELPARAM_VALUE.FONT_FILE PARAM_VALUE.FONT_FILE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FONT_FILE}] ${MODELPARAM_VALUE.FONT_FILE}
}

proc update_MODELPARAM_VALUE.FONT_WIDTH { MODELPARAM_VALUE.FONT_WIDTH PARAM_VALUE.FONT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FONT_WIDTH}] ${MODELPARAM_VALUE.FONT_WIDTH}
}

proc update_MODELPARAM_VALUE.FONT_HEIGHT { MODELPARAM_VALUE.FONT_HEIGHT PARAM_VALUE.FONT_HEIGHT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FONT_HEIGHT}] ${MODELPARAM_VALUE.FONT_HEIGHT}
}

