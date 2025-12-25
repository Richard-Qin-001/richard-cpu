#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include <iomanip>
#include "Vregfile.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    auto* top = new Vregfile;

    Verilated::traceEverOn(true);
    auto* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waves/regfile.vcd");

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

    std::cout << "Starting RegFile Test..." << std::endl;

    top->we = 1;
    top->rd_addr = 1;
    top->rd_data = 0xDEADBEEF;
    tick();

    top->rd_addr = 0;
    top->rd_data = 0x12345678;
    tick();

    top->we = 0;
    top->rs1_addr = 1;
    top->rs2_addr = 0;
    top->eval();

    std::cout << "Read x1: 0x" << std::hex << top->rs1_data << " (Expected: deadbeef)" << std::endl;
    std::cout << "Read x0: 0x" << std::hex << top->rs2_data << " (Expected: 0)" << std::endl;

    tfp->close();
    top->final();
    delete top;
    delete tfp;
    return 0;
}