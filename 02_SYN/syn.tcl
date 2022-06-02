
set search_path      ". /home/raid7_2/course/cvsd/CBDK_IC_Contest/CIC/SynopsysDC/db /home/raid7_4/raid1_1/linux/synopsys/synthesis/2017.09-sp2/dw $search_path"
set target_library   {slow.db typical.db fast.db}
set link_library     "* $target_library dw_foundation.sldb"
set symbol_library   "tsmc13.sdb generic.sdb"
set synthetic_library "dw_foundation.sldb"
set default_schematic_options {-size infinite}

set hdlin_translate_off_skip_text "TRUE"
set edifout_netlist_only "TRUE"
set verilogout_no_tri true
set plot_command {lpr -Plw}
set hdlin_auto_save_templates "TRUE"
set compile_fix_multiple_port_nets "TRUE"

set DESIGN "QRD"
set CLOCK "clk"
set CLOCK_PERIOD 4.0
read_file -format verilog ../01_RTL/$DESIGN\.v

current_design $DESIGN
link

create_clock $CLOCK -period $CLOCK_PERIOD
set_ideal_network -no_propagate $CLOCK
set_dont_touch_network [get_ports clk]

set_clock_uncertainty  0.1  $CLOCK
set_input_delay  [ expr $CLOCK_PERIOD*0.5 ] -clock $CLOCK [all_inputs]
set_output_delay [ expr $CLOCK_PERIOD*0.5 ] -clock $CLOCK [all_outputs]
set_drive 1 [all_inputs]
set_load  0.05 [all_outputs]

set_min_library slow.db -min_version fast.db
set_wire_load_mode top

check_design

uniquify
set_fix_multiple_port_nets -all -buffer_constants  [get_designs *]
set_fix_hold [all_clocks]

replace_clock_gates -global
set_ideal_network -no_propagate [get_nets *_clk]

compile_ultra
# compile_ultra -incremental
optimize_netlist -area
optimize_netlist -area
optimize_netlist -area
optimize_netlist -area
optimize_netlist -area

report_clock_gating
report_clock_gating -gating_elements
report_clock_gating -ungated -verbose

report_area > Report/$DESIGN\.area
report_power > Report/$DESIGN\.power
report_timing -path full -delay max > Report/$DESIGN\.timing
report_timing_requirements -ignored

set bus_inference_style "%s\[%d\]"
set bus_naming_style "%s\[%d\]"
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed "a-z A-Z 0-9 _" -max_length 255 -type cell
define_name_rules name_rule -allowed "a-z A-Z 0-9 _[]" -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive

write -format verilog -hierarchy -output Netlist/$DESIGN\_SYN.v
write_sdf -version 2.1 -context verilog Netlist/$DESIGN\_SYN.sdf
write_sdc Netlist/$DESIGN\_SYN.sdc

exit
