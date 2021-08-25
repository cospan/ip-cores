# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Configuration}]
  set_property tooltip {Configure Main AXI Lite Control/AXI Stream/FIFO} ${Page_0}
  #Adding Group
  set AXI_Control_Config [ipgui::add_group $IPINST -name "AXI Control Config" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${AXI_Control_Config}
  ipgui::add_param $IPINST -name "INVERT_AXI_RESET" -parent ${AXI_Control_Config}

  #Adding Group
  set AXI_Stream_Config [ipgui::add_group $IPINST -name "AXI Stream Config" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "AXIS_DATA_WIDTH" -parent ${AXI_Stream_Config}
  ipgui::add_param $IPINST -name "AXIS_DATA_USER_WIDTH" -parent ${AXI_Stream_Config}
  ipgui::add_param $IPINST -name "INVERT_AXIS_RESET" -parent ${AXI_Stream_Config}

  #Adding Group
  set FIFO_Config [ipgui::add_group $IPINST -name "FIFO Config" -parent ${Page_0}]
  ipgui::add_param $IPINST -name "FIFO_DEPTH" -parent ${FIFO_Config}



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

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.FIFO_DATA_WIDTH { PARAM_VALUE.FIFO_DATA_WIDTH } {
	# Procedure called to update FIFO_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_DATA_WIDTH { PARAM_VALUE.FIFO_DATA_WIDTH } {
	# Procedure called to validate FIFO_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to update FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIFO_DEPTH { PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to validate FIFO_DEPTH
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


proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
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

proc update_MODELPARAM_VALUE.FIFO_DATA_WIDTH { MODELPARAM_VALUE.FIFO_DATA_WIDTH PARAM_VALUE.FIFO_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DATA_WIDTH}] ${MODELPARAM_VALUE.FIFO_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.FIFO_DEPTH { MODELPARAM_VALUE.FIFO_DEPTH PARAM_VALUE.FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIFO_DEPTH}] ${MODELPARAM_VALUE.FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.INVERT_AXI_RESET { MODELPARAM_VALUE.INVERT_AXI_RESET PARAM_VALUE.INVERT_AXI_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVERT_AXI_RESET}] ${MODELPARAM_VALUE.INVERT_AXI_RESET}
}

proc update_MODELPARAM_VALUE.INVERT_AXIS_RESET { MODELPARAM_VALUE.INVERT_AXIS_RESET PARAM_VALUE.INVERT_AXIS_RESET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INVERT_AXIS_RESET}] ${MODELPARAM_VALUE.INVERT_AXIS_RESET}
}

