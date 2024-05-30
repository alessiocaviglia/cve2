#include <iostream>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vvcve2_fracturable_adder.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);
    Vvcve2_fracturable_adder *top = new Vvcve2_fracturable_adder;

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);    // Trace 99 levels of hierarchy
    tfp->open("wave.vcd");  // Open the waveform file

    top->operand_a_i = 0;
    top->operand_b_i = 0;
    top->sew_i = 0;

    while (sim_time < MAX_SIM_TIME) {
        if (sim_time == 0 || sim_time == 1) {
            top->operand_a_i = 101058054;
            top->operand_b_i = 16843009;
            top->sew_i = 2;
        }
        if (sim_time == 2 || sim_time == 3) {
            top->operand_a_i = 101058054;
            top->operand_b_i = 16843009;
            top->sew_i = 1;
        }
        if (sim_time == 4 || sim_time == 5) {
            top->operand_a_i = 101058054;
            top->operand_b_i = 16843009;
            top->sew_i = 0;
        }
        if (sim_time == 6 || sim_time == 7) {
            top->operand_a_i = 4311810304;
            top->operand_b_i = 4311810304;
            top->sew_i = 2;
        }
        if (sim_time == 8 || sim_time == 9) {
            top->operand_a_i = 4311810304;
            top->operand_b_i = 4311810304;
            top->sew_i = 1;
        }
        if (sim_time == 10 || sim_time == 11) {
            top->operand_a_i = 4311810304;
            top->operand_b_i = 4311810304;
            top->sew_i = 0;
        }
        top->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    delete top;
    return 0;
}