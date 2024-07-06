compile_core:
	fusesoc --cores-root ../ run --no-export --tool=verilator --setup --build alessiocaviglia:thesis:vcve2_sim:0.1

simulate_alu: clean_alu
	fusesoc --cores-root ../ run --no-export --tool=verilator --setup --build --run openhwgroup:cve2:alu_sim:0.1 2>&1 | tee buildsim.log

simulate_core: clean_core
	fusesoc --cores-root ../ run --no-export --tool=verilator --setup --build --run alessiocaviglia:thesis:vcve2_sim:0.1 2>&1 | tee buildsim.log
	gtkwave build/alessiocaviglia_vcve2_vcve2_sim_0.1/default-verilator/waveform.vcd

view_core:
	gtkwave build/alessiocaviglia_vcve2_vcve2_sim_0.1/default-verilator/waveform.vcd

simulate_vregfile: clean_vregfile
	fusesoc --cores-root ../ run --no-export --tool=verilator --setup --build --run openhwgroup:cve2:vregfile_sim:0.1 2>&1 | tee buildsim.log
	gtkwave build/openhwgroup_cve2_vregfile_sim_0.1/default-verilator/waveform.vcd

clean_alu:
	rm -rf build/openhwgroup-cve2-alu_sim-0.1

clean_core:
	rm -rf build/openhwgroup-cve2-cve2_sim-0.1

clean_vregfile:
	rm -rf build/openhwgroup-cve2-vregfile_sim-0.1
