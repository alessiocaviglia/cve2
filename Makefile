CVE2_CONFIG ?= small

FUSESOC_CONFIG_OPTS = $(shell ./util/cve2_config.py $(CVE2_CONFIG) fusesoc_opts)

# SYNTHESIS
SYNTHESIS_DIR			:= $(HOME)/repo/thesis/hw/cve2/syn/build
SYN_NETLIST_DIR			:= $(HOME)/repo/thesis/hw/cve2/syn/netlist
SYN_LOG_DIR				:= $(SYNTHESIS_DIR)/logs
SYN_SCRIPTS_DIR			:= $(HOME)/repo/thesis/hw/cve2/syn/scripts

all: help

.PHONY: help
help:
	@echo "This is a short hand for running popular tasks."
	@echo "Please check the documentation on how to get started"
	@echo "or how to set-up the different environments."

##########
# THESIS #
##########

#------------#
# Simulation #
#------------#

# CORE-ONLY COMPILE
# Used to quickly compile the core for simulation
.PHONY: compile_core
compile_core:
	fusesoc --cores-root . run --no-export --tool=verilator --setup --build alessiocaviglia:thesis:vcve2_sim:0.1

#-----------#
# Synthesis #
#-----------#

# SYNTHESIZE THE MODEL USING SYNOPSYS DESIGN COMPILER
# USAGE: make syn-core  
.PHONY: syn-core
syn-core:
	make clean-syn
	mkdir -p $(SYN_NETLIST_DIR)
	fusesoc --cores-root . run --build-root $(SYNTHESIS_DIR) --target=synth --tool=design_compiler --setup --build alessiocaviglia:thesis:vcve2_top 2>&1 | tee buildsim.log
	cp $(SYNTHESIS_DIR)/synth-design_compiler/netlist.v $(SYN_NETLIST_DIR)/netlist.v

#-------#
# Utils #
#-------#

.PHONY: clean-syn
clean-syn:
	rm -rf $(SYNTHESIS_DIR)
	rm -rf $(SYN_NETLIST_DIR)

.PHONY: prepare-syn-sim
prepare-syn-sim:
	cp -n /software/dk/tsmc65/digital/Front_End/verilog/tcbn65lp_200a/tcbn65lp.v $(SYN_NETLIST_DIR)/tcbn65lp.v
