###################################################################

# Created by write_sdc on Wed Jan 29 11:21:53 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports clk_i]  -name INPUT_CLK  -period 0  -waveform {0 0}
