#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include <iomanip>
#include "Vmemory.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    auto* top = new Vmemory;

    Verilated::traceEverOn(true);
    auto*tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waves/memory.vcd");

    vluint64_t main_time = 0;

    auto tick = [&](){
        top->clk = 0;
        top->eval();
        tfp->dump(main_time++);
        top->clk = 1;
        top->eval();
        tfp->dump(main_time++);
    };

    std::cout << "Starting Memory Test..." << std::endl;

    top->we = 1;
    top->addr = 0x4;
    top->write_data = 0x12345678;
    tick();

    top->addr = 0x8;
    top->write_data = 0xABCDE001;
    tick();

    top->we = 0;

    top->addr = 0x4;
    top->eval();
    std::cout << "Read Addr 0x4: 0x" << std::hex << top->read_data << " (Expected: 12345678)" << std::endl;

    top->addr = 0x8;
    top->eval();
    std::cout << "Read Addr 0x8: 0x" << std::hex << top->read_data << " (Expected: abcde001)" << std::endl;

    tfp->close();
    top->final();
    delete top;
    delete tfp;
    return 0;
}