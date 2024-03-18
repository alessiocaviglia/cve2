#include <verilated.h>
#include <verilated_vcd_c.h>

#include <iostream>

#include "Vvregfile_wrapper.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {
  // Instantiate DUT
  Vvregfile_wrapper *dut = new Vvregfile_wrapper;

  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  // Initialize simulation inputs
  dut->clk_i = 0;
  dut->rst_ni = 0;
  dut->we_i = 0;
  dut->req_i = 0;
  dut->raddr_1_i = 0;
  dut->raddr_2_i = 0;
  dut->raddr_3_i = 0;
  for (int i = 0; i < 4; i++) dut->wdata_i[i] = 0;

  while (sim_time < MAX_SIM_TIME) {
    dut->clk_i ^= 1;
    dut->we_i = 0;
    dut->req_i = 0;

    // read request
    if (sim_time == 4) {
      dut->rst_ni = 1;
      dut->req_i = 1;
      dut->raddr_1_i = 0;
      dut->raddr_2_i = 1;
      dut->raddr_3_i = 2;
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