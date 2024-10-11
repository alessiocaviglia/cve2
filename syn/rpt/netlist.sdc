###################################################################

# Created by write_sdc on Thu Oct 10 15:07:12 2024

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports clk_i]  -name INPUT_CLK  -period 4.95  -waveform {0 2.475}
