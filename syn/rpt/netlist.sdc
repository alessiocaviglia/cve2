###################################################################

# Created by write_sdc on Wed Oct 16 11:35:46 2024

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports clk_i]  -name INPUT_CLK  -period 0  -waveform {0 0}
