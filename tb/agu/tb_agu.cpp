#include <iostream>

#include "Vvce2_agu.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {
  Verilated::commandArgs(argc, argv);
  Vvce2_agu *top = new Vvce2_agu;

  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  top->trace(tfp, 99);    // Trace 99 levels of hierarchy
  tfp->open("wave.vcd");  // Open the waveform file

  top->clk_i = 0;
  top->rst_ni = 0;
  top->load = 0;
  top->get_rs1 = 0;
  top->get_rs2 = 0;
  top->get_rd_noincr = 0;
  top->get_rd = 0;
  top->addr_rs1_i = 0;
  top->addr_rs2_i = 0;
  top->addr_rd_i = 0;

  while (sim_time < MAX_SIM_TIME) {
    top->clk_i ^= 1;
    top->load = 0;
    top->get_rs1 = 0;
    top->get_rs2 = 0;
    top->get_rd_noincr = 0;
    top->get_rd = 0;
    top->addr_rs1_i = 0;
    top->addr_rs2_i = 0;
    top->addr_rd_i = 0;
    if (sim_time == 2 || sim_time == 3) {
      top->rst_ni = 1;
    }
    if (sim_time == 4 || sim_time == 5) {
      top->load = 1;
      top->addr_rs1_i = 10;
      top->addr_rs2_i = 20;
      top->addr_rd_i = 30;
    }
    if (sim_time == 6 || sim_time == 7) {
        top->get_rs1 = 1;
    }
    if (sim_time == 8 || sim_time == 9) {
        top->get_rs2 = 1;
    }
    if (sim_time == 10 || sim_time == 11) {
        top->get_rd_noincr = 1;
    }
    if (sim_time == 12 || sim_time == 13) {
        top->get_rd = 1;
    }
    top->eval();
    tfp->dump(sim_time);
    sim_time++;
  }
  /*
  // Reset
  top->rst_ni = 0;
  top->eval();
  top->clk_i = !top->clk_i;
  top->eval();

  // Release reset
  top->rst_ni = 1;
  top->eval();
  top->clk_i = !top->clk_i;
  top->eval();

  // Apply some inputs and print the output
  top->load = 1;
  top->addr_rs1_i = 10;
  top->addr_rs2_i = 20;
  top->addr_rd_i = 30;
  top->eval();
  top->clk_i = !top->clk_i;
  top->eval();
  std::cout << "addr_o: " << top->addr_o << std::endl; */

  tfp->close();
  delete top;
  return 0;
}