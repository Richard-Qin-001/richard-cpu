#include <verilated.h>
#include <verilated_vcd_c.h>
#include <iostream>
#include <iomanip>

#include "Vcounter.h"

int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);

    auto* counter = new Vcounter;

    Verilated::traceEverOn(true);
    auto* tfp = new VerilatedVcdC;
    counter->trace(tfp, 99);
    tfp->open("waves/counter.vcd");

    vluint64_t main_time = 0;
    counter->clk = 0;
    counter->rst_n = 0;

    std::cout << std::setw(10) << "Time"
              << std::setw(10) << "Reset"
              << std::setw(10) << "Count" << std::endl;
    
    while (main_time < 200)
    {
        if(main_time > 10) counter->rst_n = 1;
        if((main_time % 5) == 0) counter->clk = !counter->clk;

        counter->eval();

        if (counter->clk)
        {
            std::cout << std::setw(10) << main_time
                      << std::setw(10) << static_cast<int>(counter->rst_n)
                      << std::setw(10) << static_cast<int>(counter->count) << std::endl;
        }
        tfp->dump(main_time);
        main_time++;
    }

    std::cout << "Simulation Finished. Steps run: " << main_time << std::endl;

    tfp->close();
    counter->final();
    delete counter;
    delete tfp;
    return 0;
}