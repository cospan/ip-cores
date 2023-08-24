# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI Config}]
  set_property tooltip {Configure AXI Lite and AXI Stream} ${Page_0}
  ipgui::add_static_text $IPINST -name "AXI Lite Config" -parent ${Page_0} -text {AXI LIte Config}
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INVERT_AXI_RESET" -parent ${Page_0}
  ipgui::add_static_text $IPINST -name "AXI Stream Config" -parent ${Page_0} -text {AXI Stream Config}
  ipgui::add_param $IPINST -name "AXIS_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEFAULT_INTERVAL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEFAULT_TAB_COUNT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEFAULT_X_END" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEFAULT_X_START" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEFAULT_Y_END" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DEFAULT_Y_START" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FONT_FILE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FONT_HEIGHT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FONT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INVERT_AXIS_RESET" -parent ${Page_0}

  #Adding Page
  set Character_Config [ipgui::add_page $IPINST -name "Character Config"]
  ipgui::add_param $IPINST -name "CONSOLE_DEPTH" -parent ${Character_Config}

  #Adding Page
  set Image_Config [ipgui::add_page $IPINST -name "Image Config"]
  ipgui::add_param $IPINST -name "IMAGE_WIDTH" -parent ${Image_Config}
  ipgui::add_param $IPINST -name "IMAGE_HEIGHT" -parent ${Image_Config}
  ipgui::add_param $IPINST -name "FOREGROUND_COLOR" -parent ${Image_Config}
  ipgui::add_param $IPINST -name "BACKGROUND_COLOR" -parent ${Image_Config}
  ipgui::add_param $IPINST -name "DEFAULT_ALPHA" -parent ${Image_Config}


}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.AXIS_WIDTH { PARAM_VALUE.AXIS_WIDTH } {
	# Procedure called to update AXIS_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXIS_WIDTH { PARAM_VALUE.AXIS_WIDTH } {
	# Procedure called to validate AXIS_WIDTH
	return true
}

proc update_PARAM_VALUE.BACKGROUND_COLOR { PARAM_VALUE.BACKGROUND_COLOR } {
	# Procedure called to update BACKGROUND_COLOR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BACKGROUND_COLOR { PARAM_VALUE.BACKGROUND_COLOR } {
	# Procedure called to validate BACKGROUND_COLOR
	return true
}

proc update_PARAM_VALUE.CONSOLE_DEPTH { PARAM_VALUE.CONSOLE_DEPTH } {
	# Procedure called to update CONSOLE_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CONSOLE_DEPTH { PARAM_VALUE.CONSOLE_DEPTH } {
	# Procedure called to validate CONSOLE_DEPTH
	return true
}

proc update_PARAM_VALUE.DEFAULT_ALPHA { PARAM_VALUE.DEFAULT_ALPHA } {
	# Procedure called to update DEFAULT_ALPHA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_ALPHA { PARAM_VALUE.DEFAULT_ALPHA } {
	# Procedure called to validate DEFAULT_ALPHA
	return true
}

proc update_PARAM_VALUE.DEFAULT_INTERVAL { PARAM_VALUE.DEFAULT_INTERVAL } {
	# Procedure called to update DEFAULT_INTERVAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_INTERVAL { PARAM_VALUE.DEFAULT_INTERVAL } {
	# Procedure called to validate DEFAULT_INTERVAL
	return true
}

proc update_PARAM_VALUE.DEFAULT_TAB_COUNT { PARAM_VALUE.DEFAULT_TAB_COUNT } {
	# Procedure called to update DEFAULT_TAB_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_TAB_COUNT { PARAM_VALUE.DEFAULT_TAB_COUNT } {
	# Procedure called to validate DEFAULT_TAB_COUNT
	return true
}

proc update_PARAM_VALUE.DEFAULT_X_END { PARAM_VALUE.DEFAULT_X_END } {
	# Procedure called to update DEFAULT_X_END when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_X_END { PARAM_VALUE.DEFAULT_X_END } {
	# Procedure called to validate DEFAULT_X_END
	return true
}

proc update_PARAM_VALUE.DEFAULT_X_START { PARAM_VALUE.DEFAULT_X_START } {
	# Procedure called to update DEFAULT_X_START when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_X_START { PARAM_VALUE.DEFAULT_X_START } {
	# Procedure called to validate DEFAULT_X_START
	return true
}

proc update_PARAM_VALUE.DEFAULT_Y_END { PARAM_VALUE.DEFAULT_Y_END } {
	# Procedure called to update DEFAULT_Y_END when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_Y_END { PARAM_VALUE.DEFAULT_Y_END } {
	# Procedure called to validate DEFAULT_Y_END
	return true
}

proc update_PARAM_VALUE.DEFAULT_Y_START { PARAM_VALUE.DEFAULT_Y_START } {
	# Procedure called to update DEFAULT_Y_START when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_Y_START { PARAM_VALUE.DEFAULT_Y_START } {
	# Procedure called to validate DEFAULT_Y_START
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

proc update_PARAM_VALUE.FOREGROUND_COLOR { PARAM_VALUE.FOREGROUND_COLOR } {
	# Procedure called to update FOREGROUND_COLOR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FOREGROUND_COLOR { PARAM_VALUE.FOREGROUND_COLOR } {
	# Procedure called to validate FOREGROUND_COLOR
	return true
}

proc update_PARAM_VALUE.IMAGE_HEIGHT { PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to update IMAGE_HEIGHT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMAGE_HEIGHT { PARAM_VALUE.IMAGE_HEIGHT } {
	# Procedure called to validate IMAGE_HEIGHT
	return true
}

proc update_PARAM_VALUE.IMAGE_WIDTH { PARAM_VALUE.IMAGE_WIDTH } {
	# Procedure called to update IMAGE_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMAGE_WIDTH { PARAM_VALUE.IMAGE_WIDTH } {
	# Procedure called to validate IMAGE_WIDTH
	return true
}

proc update_PARAM_VALUE.INVERT_AXIS_RESET { PARAM_VALUE.INVERT_AXIS_RESET } {
	# Procedure called to update INVERT_AXIS_RESET when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INVERT_AXIS_RESET { PARAM_VALUE.INVERT_AXIS_RESET } {
	# Procedure called to validate INVERT_AXIS_RESET
	return true
}

proc update_PARAM_VALUE.INVERT_AXI_RESET { PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to update INVERT_AXI_RESET when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INVERT_AXI_RESET { PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to validate INVERT_AXI_RESET
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

proc update_MODELPARAM_VALUE.FOREGROUND_COLOR { MODELPARAM_VALUE.FOREGROUND_COLOR PARAM_VALUE.FOREGROUND_COLOR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FOREGROUND_COLOR}] ${MODELPARAM_VALUE.FOREGROUND_COLOR}
}

proc update_MODELPARAM_VALUE.BACKGROUND_COLOR { MODELPARAM_VALUE.BACKGROUND_COLOR PARAM_VALUE.BACKGROUND_COLOR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BACKGROUND_COLOR}] ${MODELPARAM_VALUE.BACKGROUND_COLOR}
}

proc update_MODELPARAM_VALUE.DEFAULT_INTERVAL { MODELPARAM_VALUE.DEFAULT_INTERVAL PARAM_VALUE.DEFAULT_INTERVAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_INTERVAL}] ${MODELPARAM_VALUE.DEFAULT_INTERVAL}
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

proc update_MODELPARAM_VALUE.DEFAULT_ALPHA { MODELPARAM_VALUE.DEFAULT_ALPHA PARAM_VALUE.DEFAULT_ALPHA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_ALPHA}] ${MODELPARAM_VALUE.DEFAULT_ALPHA}
}

proc update_MODELPARAM_VALUE.DEFAULT_TAB_COUNT { MODELPARAM_VALUE.DEFAULT_TAB_COUNT PARAM_VALUE.DEFAULT_TAB_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_TAB_COUNT}] ${MODELPARAM_VALUE.DEFAULT_TAB_COUNT}
}

proc update_MODELPARAM_VALUE.DEFAULT_X_START { MODELPARAM_VALUE.DEFAULT_X_START PARAM_VALUE.DEFAULT_X_START } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_X_START}] ${MODELPARAM_VALUE.DEFAULT_X_START}
}

proc update_MODELPARAM_VALUE.DEFAULT_X_END { MODELPARAM_VALUE.DEFAULT_X_END PARAM_VALUE.DEFAULT_X_END } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_X_END}] ${MODELPARAM_VALUE.DEFAULT_X_END}
}

proc update_MODELPARAM_VALUE.DEFAULT_Y_START { MODELPARAM_VALUE.DEFAULT_Y_START PARAM_VALUE.DEFAULT_Y_START } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_Y_START}] ${MODELPARAM_VALUE.DEFAULT_Y_START}
}

proc update_MODELPARAM_VALUE.DEFAULT_Y_END { MODELPARAM_VALUE.DEFAULT_Y_END PARAM_VALUE.DEFAULT_Y_END } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_Y_END}] ${MODELPARAM_VALUE.DEFAULT_Y_END}
}

proc update_MODELPARAM_VALUE.AXIS_WIDTH { MODELPARAM_VALUE.AXIS_WIDTH PARAM_VALUE.AXIS_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXIS_WIDTH}] ${MODELPARAM_VALUE.AXIS_WIDTH}
}

proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.INVERT_AXIS_RESET { MODELPARAM_VALUE.INVERT_AXIS_RESET PARAM_VALUE.INVERT_AXIS_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVERT_AXIS_RESET}] ${MODELPARAM_VALUE.INVERT_AXIS_RESET}
}

proc update_MODELPARAM_VALUE.INVERT_AXI_RESET { MODELPARAM_VALUE.INVERT_AXI_RESET PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVERT_AXI_RESET}] ${MODELPARAM_VALUE.INVERT_AXI_RESET}
}

