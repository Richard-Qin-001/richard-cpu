module memory (
    input wire clk,
    input wire we,
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [31:0] addr,
    /* verilator lint_off UNUSEDSIGNAL */
    input wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] ram [1023:0];

    assign read_data = ram[addr[11:2]];

    always @(posedge clk) begin
        if (we) begin
            ram[addr[11:2]] <= write_data;
        end

    end

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            ram[i] = 32'b0;
        end
        $readmemh("test.txt", ram);
    end
    
endmodule
