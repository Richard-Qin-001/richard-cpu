module top (
    input wire clk,
    input wire rst_n,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instr,
    output wire [31:0] debug_alu_out
);
    reg [31:0] pc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'b0;
        end
        else begin
            pc <= pc + 4;
        end
    end

    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] instr;
    /* verilator lint_on UNUSEDSIGNAL */

    memory inst_mem (
        .clk(clk),
        .we(1'b0),
        .addr(pc),
        .write_data(32'b0),
        .read_data(instr)
    );

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd = instr[11:7];
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [31:0] imm = {{20{instr[31]}}, instr[31:20]};

    wire [31:0] rs1_data, rs2_data;
    wire reg_we = (opcode == 7'b0010011 || opcode == 7'b0110011);

    regfile rf (
        .clk(clk),
        .we(reg_we),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(alu_out),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    wire [31:0] alu_out;
    wire [31:0] alu_b = (opcode == 7'b0010011) ? imm : rs2_data;
    /* verilator lint_off UNUSEDSIGNAL */
    wire alu_zero;
    /* verilator lint_on UNUSEDSIGNAL */
    alu my_alu (
        .a(rs1_data),
        .b(alu_b),
        .alu_op(4'b0000),
        .result(alu_out),
        .zero(alu_zero)
    );

    assign debug_pc = pc;
    assign debug_instr = instr;
    assign debug_alu_out = alu_out;

endmodule
