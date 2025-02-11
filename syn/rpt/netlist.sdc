###################################################################

# Created by write_sdc on Thu Feb  6 12:31:33 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports clk_i]  -name INPUT_CLK  -period 2  -waveform {0 1}
