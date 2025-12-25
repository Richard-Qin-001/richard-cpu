#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include <iomanip>
#include "Valu.h"

int main(int argc, char ** argv)
{
    Verilated::commandArgs(argc, argv);
    auto* top = new Valu;

    Verilated::traceEverOn(true);
    auto* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waves/alu.vcd");
    vluint64_t main_time = 0;

    auto test_alu = [&](uint32_t a, uint32_t b, uint8_t op, std::string name)
    {
        top->a = a;
        top->b = b;
        top->alu_op = op;
        top->eval();

        tfp->dump(main_time);
        main_time += 10;

        std::cout << std::left << std::setw(10) << name
                  << " | A: " << std::setw(10) << (int32_t)a
                  << " B: " << std::setw(10) << (int32_t)b
                  << " | Result: " << std::setw(10) << (int32_t)top->result
                  << " Zero: " << (int)top->zero << std::endl;
    };
    std::cout << "Start ALU Unit Test..." << std::endl;
    std::cout << std::string(80, '-') << std::endl;

    test_alu(10, 20, 0, "ADD");
    test_alu(30, 10, 8, "SUB");

    test_alu(0xAAAA5555, 0xFFFF0000, 7, "AND"); // 4'b0111
    test_alu(0xAAAA5555, 0x0000FFFF, 6, "OR");  // 4'b0110
    test_alu(0xFFFFFFFF, 0xFFFFFFFF, 4, "XOR"); // 4'b0100

    test_alu(1, 4, 1, "SLL (1<<4)");   // 4'b0001 -> 16
    test_alu(16, 2, 5, "SRL (16>>2)"); // 4'b0101 -> 4

    test_alu(0x80000000, 2, 13, "SRA (Neg)"); // 4'b1101 -> 0xE0000000

    test_alu(-10, 5, 2, "SLT (Sgn)");   // 4'b0010
    test_alu(-10, 5, 3, "SLTU (Usgn)"); // 4'b0011

    test_alu(0x123, 0x123, 8, "ZERO_CHECK");

    std::cout << std::string(80, '-') << std::endl;

    tfp->close();
    delete top;
    delete tfp;
    return (0);
}