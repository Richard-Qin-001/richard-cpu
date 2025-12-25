#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include <iomanip>
#include "Vtop.h"

int main(int argc, char** argv){
    Verilated::commandArgs(argc, argv);
    auto* top = new Vtop;

    Verilated::traceEverOn(true);
    auto* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waves/top.vcd");

    vluint64_t main_time = 0;

    auto tick = [&]()
    {
        top->clk = 0;
        top->eval();
        tfp->dump(main_time++);
        top->clk = 1;
        top->eval();
        tfp->dump(main_time++);
    };

    std::cout << "Starting Top Module Simulation..." << std::endl;
    std::cout << "Running with test.txt as instruction memory." << std::endl;

    top->rst_n = 0;
    for (int i = 0; i < 2; i++)
        tick();
    top->rst_n = 1;
    top->eval();
    std::cout << "Reset de-asserted." << std::endl;

    for (int cycle = 0; cycle < 10; cycle++)
    {
        std::cout << "Cycle: " << cycle
                  << " | PC: 0x" << std::hex << std::setw(8) << std::setfill('0') << top->debug_pc
                  << " | Instr: 0x" << std::setw(8) << top->debug_instr
                  << " | ALU_Out: 0x" << top->debug_alu_out
                  << std::endl;
        tick();
    }

    tfp->close();
    top->final();
    delete top;
    delete tfp;
    return 0;
}