`include "defines"
module top (
    input wire clk,
    input wire rst_n,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instr,
    output wire [31:0] debug_alu_out
);
    reg [31:0] pc;

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

    wire [31:0] rs1_data, rs2_data;

    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm = (opcode == 7'b0100011) ? imm_s : imm_i;
    
    wire is_beq = (opcode == 7'b1100011);
    wire take_branch = is_beq && alu_zero;

    wire [31:0] pc_next;
    wire [31:0] pc_plus4 = pc + 4;
    wire [31:0] pc_target = pc + imm_b;

    assign pc_next = take_branch ? pc_target : pc_plus4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'b0;
        end
        else begin
            pc <= pc_next;
        end
    end

    wire is_lw = (opcode == 7'b0000011);
    wire is_sw = (opcode == 7'b0100011);
    wire reg_we = (opcode == 7'b0010011 || opcode == 7'b0110011 || is_lw);

    wire [31:0] mem_read_data;

    memory data_mem (
        .clk(clk),
        .we(is_sw),
        .addr(alu_out),
        .write_data(rs2_data),
        .read_data(mem_read_data)
    );

    wire [31:0] rf_wd = is_lw ? mem_read_data : alu_out;

    regfile rf (
        .clk(clk),
        .we(reg_we),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(rf_wd),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    wire [31:0] alu_out;
    wire [31:0] alu_b = (opcode == 7'b0010011 || is_lw || is_sw) ? imm : rs2_data;
    /* verilator lint_off UNUSEDSIGNAL */
    wire alu_zero;
    /* verilator lint_on UNUSEDSIGNAL */
    wire [3:0] alu_ctrl = is_beq ? `ALU_SUB : `ALU_ADD;

    alu my_alu (
        .a(rs1_data),
        .b(alu_b),
        .alu_op(alu_ctrl),
        .result(alu_out),
        .zero(alu_zero)
    );

    assign debug_pc = pc;
    assign debug_instr = instr;
    assign debug_alu_out = alu_out;

endmodule
