module memory (
    input wire clk,
    input wire [3:0] be,
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [31:0] addr,
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] ram [1023:0];

    assign read_data = ram[addr[11:2]];

    always @(posedge clk) begin
        if (be[0]) ram[addr[11:2]][7:0]   <= write_data[7:0];
        if (be[1]) ram[addr[11:2]][15:8]  <= write_data[15:8];
        if (be[2]) ram[addr[11:2]][23:16] <= write_data[23:16];
        if (be[3]) ram[addr[11:2]][31:24] <= write_data[31:24];
    end

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            ram[i] = 32'b0;
        end
        $readmemh("machine_code.txt", ram);
    end
    
endmodule
