set init_remove_assigns 1

# Global nets (power)
set_db init_ground_nets $design(all_ground_nets)
set_db init_power_nets $design(all_power_nets)

# Non andare oltre a 4 su Saruman, perché ogni thread usa una licenza
set_multi_cpu_usage -local_cpu 2

# Process node and mapping effort
set_db design_process_node 65
set_db design_flow_effort standard

# I/O pads (non credo che ti serva)
#read_mmmc     $design(mmmc_view_file)

# Logic libraries
read_physical -lefs $design(ALL_LEFS)
read_netlist  $design(netlist)

init_design

delete_empty_hinsts
delete_assigns -add_buffer
