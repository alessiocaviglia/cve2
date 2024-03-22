#include <verilated.h>

#include "Vvcve2_core.h"
#include "verilated_vcd_c.h"  // Include the VCD tracing header

#define MAX_SIM_TIME 100
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {
  // Initialize Verilators variables
  Verilated::commandArgs(argc, argv);
  // Create an instance of our module under test
  Vvcve2_core *top = new Vvcve2_core;

  // Initialize VCD tracing
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  top->trace(tfp, 99);        // Trace 99 levels of hierarchy
  tfp->open("waveform.vcd");  // Open the VCD file

  // I initialized clock and reset t 0 (reset is active low)
  top->clk_i = 0;
  top->rst_ni = 1;

  // weird signals
  top->test_en_i = 0;
  top->hart_id_i = 0;
  top->boot_addr_i = 0;

  // Instruction memory interface
  top->instr_req_o = 0;
  top->instr_gnt_i = 0;
  top->instr_rvalid_i = 0;
  top->instr_addr_o = 0;
  top->instr_rdata_i = 0;
  top->instr_err_i = 0;

  // Data memory interface
  top->data_req_o = 0;
  top->data_gnt_i = 0;
  top->data_rvalid_i = 0;
  top->data_we_o = 0;
  top->data_be_o = 0;
  top->data_addr_o = 0;
  top->data_wdata_o = 0;
  top->data_rdata_i = 0;
  top->data_err_i = 0;

  // Interrupt inputs
  top->irq_software_i = 0;
  top->irq_timer_i = 0;
  top->irq_external_i = 0;
  top->irq_fast_i = 0;
  top->irq_nm_i = 0;
  top->irq_pending_o = 0;

  // Debug Interface
  top->debug_req_i = 0;
  // CPU Control Signals
  top->fetch_enable_i = 0;
  top->core_busy_o = 0;

  printf("Henlo fren! Starting simulation...\n");

  while (sim_time<MAX_SIM_TIME) {
    top->clk_i = !top->clk_i;  // Toggle the clock
    if (sim_time==10) {
      // I force one instructions
      top->instr_rdata_i = 0x5C00C0D7;
      top->instr_rvalid_i = 1;
      top->fetch_enable_i = 1;
    }
    top->eval();
    tfp->dump(sim_time);
    sim_time++;
  }

  tfp->close();

  delete top;
  return 0;
}