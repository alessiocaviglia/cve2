#include <verilated.h>
#include <verilated_vcd_c.h>

#include <iostream>

#include "Vvcve2_vrf_interface.h"

#define MAX_SIM_TIME 50
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {
  // Instantiate DUT
  Vvcve2_vrf_interface *dut = new Vvcve2_vrf_interface;

  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  // Initialize simulation inputs
  dut->clk_i = 1;
  dut->rst_ni = 0;
  dut->we_i = 0;
  dut->req_i = 0;
  dut->raddr_a_i = 0;
  dut->raddr_b_i = 0;
  dut->waddr_i = 0;
  dut->wdata_i = 0;
  // Data memory
  dut->data_gnt_i = 0;
  dut->data_rvalid_i = 0;
  dut->data_err_i = 0;
  dut->data_pmp_err_i = 0;
  dut->data_rdata_i = 0;
  // AGU
  dut->agu_ready_i = 0;
  dut->sel_operation_i = 0;
  dut->lmul_i = 6;

  while (sim_time < MAX_SIM_TIME) {
    dut->clk_i ^= 1;
    dut->we_i = 0;
    //dut->req_i = 0;
    dut->agu_ready_i = 0;

    // 2 source operands
    if (sim_time == 5 || sim_time == 6) {
      dut->rst_ni = 1;
      dut->req_i = 1;
      dut->sel_operation_i = 11;
    }
    // confirm agu ready
    if (sim_time == 7 || sim_time == 8) {
      dut->agu_ready_i = 1;
    }

    /*// 3 source operands
    if (sim_time == 15 || sim_time == 16) {
      dut->rst_ni = 1;
      dut->req_i = 1;
      dut->sel_operation_i = 15;
    }
    // confirm agu ready
    if (sim_time == 17 || sim_time == 18) {
      dut->agu_ready_i = 1;
    } */

    // 3 source operands
    if (sim_time == 27 || sim_time == 28) {
      dut->rst_ni = 1;
      dut->req_i = 1;
      dut->sel_operation_i = 8;
    }
    // confirm agu ready
    if (sim_time == 29 || sim_time == 30) {
      dut->agu_ready_i = 1;
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