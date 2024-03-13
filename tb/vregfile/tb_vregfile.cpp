#include <verilated.h>
#include <verilated_vcd_c.h>

#include <iostream>

#include "Vvregfile.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {
  // Instantiate DUT
  Vvregfile *dut = new Vvregfile;

  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  // Initialize simulation inputs
  dut->clk_i = 0;
  dut->rst_ni = 0;
  dut->we_i = 0;
  dut->addr_i = 0;
  dut->wdata_i[0] = 0;
  dut->wdata_i[1] = 0;
  dut->wdata_i[2] = 0;
  dut->wdata_i[3] = 0;

  while (sim_time < MAX_SIM_TIME) {
    dut->clk_i ^= 1;
    dut->we_i = 0;

    if (sim_time == 5) {
      dut->rst_ni = 1;
      dut->we_i = 1;
      dut->addr_i = 0;
      dut->wdata_i[0] = 0x1234;
      dut->wdata_i[1] = 0x1234;
      dut->wdata_i[2] = 0x1234;
      dut->wdata_i[3] = 0x1234;
    }

    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;
  }

  // Cleanup
  m_trace->close();
  delete dut;

  return 0;
}