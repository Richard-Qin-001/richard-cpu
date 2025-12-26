`include "defines.v"
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
    wire [4:0] rd     = instr[11:7];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [2:0] funct3 = instr[14:12];
    /* verilator lint_off UNUSEDSIGNAL */
    wire [6:0] funct7 = instr[31:25];
    /* verilator lint_on UNUSEDSIGNAL */

    wire [31:0] rs1_data, rs2_data;

    localparam OP_I_ALU  = 7'b0010011;
    localparam OP_I_LOAD = 7'b0000011;
    localparam OP_S_TYPE = 7'b0100011;
    localparam OP_B_TYPE = 7'b1100011;
    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR = 7'b1100111;

    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};
    wire [31:0] imm_j = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    reg [31:0] imm;
    always @(*) begin
        case (opcode)
            OP_I_ALU, OP_I_LOAD, OP_JALR: imm = imm_i;
            OP_S_TYPE:           imm = imm_s;
            OP_B_TYPE:           imm = imm_b;
            OP_LUI, OP_AUIPC:    imm = imm_u;
            OP_JAL:              imm = imm_j;
            default: imm = 32'b0;
        endcase
    end
    
    wire is_jal = (opcode == OP_JAL);
    wire is_beq = (opcode == OP_B_TYPE);
    wire is_jalr = (opcode == OP_JALR);

    reg branch_condition;
    always @(*) begin
        case (funct3)
            3'b000: branch_condition = alu_zero;
            3'b001: branch_condition = !alu_zero;
            3'b100: branch_condition = alu_out[0];
            3'b101: branch_condition = !alu_out[0];
            3'b110: branch_condition = alu_out[0];
            3'b111: branch_condition = !alu_out[0];
            default: branch_condition = 1'b0;
        endcase
    end

    wire take_branch = (is_beq && branch_condition) || is_jal || is_jalr;

    wire [31:0] jump_base   = is_jalr ? rs1_data : pc;
    wire [31:0] jump_offset = is_jal  ? imm_j    : is_jalr ? imm_i : imm_b;

    wire [31:0] pc_next;
    wire [31:0] pc_target_raw = $unsigned($signed(jump_base) + $signed(jump_offset));
    wire [31:0] pc_target     = is_jalr ? (pc_target_raw & 32'hfffffffe) : pc_target_raw;
    wire [31:0] pc_plus4 = pc + 4;

    assign pc_next = take_branch ? pc_target : pc_plus4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'b0;
        end
        else begin
            pc <= pc_next;
        end
    end

    wire is_lw = (opcode == OP_I_LOAD);
    wire is_sw = (opcode == OP_S_TYPE);
    wire reg_we = (opcode == OP_I_ALU || opcode == OP_R_TYPE || is_lw || 
               opcode == OP_LUI || opcode == OP_AUIPC || is_jal || is_jalr);

    wire [31:0] mem_read_data;

    memory data_mem (
        .clk(clk),
        .we(is_sw),
        .addr(alu_out),
        .write_data(rs2_data),
        .read_data(mem_read_data)
    );

    /* verilator lint_off UNOPTFLAT */
    wire [31:0] rf_wd = is_lw ? mem_read_data : (is_jal || is_jalr) ? pc_plus4 : alu_out;
    /* verilator lint_on UNOPTFLAT */

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

    reg [3:0] alu_ctrl; 
    always @(*) begin
        case (opcode)
            OP_R_TYPE: begin
                case (funct3)
                    3'b000: alu_ctrl = funct7[5] ? `ALU_SUB : `ALU_ADD;
                    3'b101: alu_ctrl = funct7[5] ? `ALU_SRA : `ALU_SRL;
                    default: alu_ctrl = {1'b0, funct3};
                endcase
            end

            OP_I_ALU:begin
                if (funct3 == 3'b101 && funct7[5]) begin
                    alu_ctrl = `ALU_SRA;
                end
                else if (funct3 == 3'b001)
                    alu_ctrl = `ALU_SLL;
                else if (funct3 == 3'b101)
                    alu_ctrl = `ALU_SRL;
                else begin
                    alu_ctrl = {1'b0, funct3};
                end
            end

            OP_B_TYPE: begin
                case (funct3)
                    3'b000, 3'b001: alu_ctrl = `ALU_SUB;
                    3'b100, 3'b101: alu_ctrl = `ALU_SLT;
                    3'b110, 3'b111: alu_ctrl = `ALU_SLTU;
                    default: alu_ctrl = `ALU_SUB;
                endcase
            end

            OP_JALR: alu_ctrl = `ALU_ADD;
            default: alu_ctrl = `ALU_ADD;
        endcase
    end

    wire [31:0] alu_out;
    wire use_imm = (opcode == OP_I_ALU || opcode == OP_I_LOAD || opcode == OP_S_TYPE || opcode == OP_LUI || opcode == OP_AUIPC);
    wire [31:0] alu_a = (opcode == OP_AUIPC) ? pc : (opcode == OP_LUI)   ? 32'b0 : rs1_data;
    wire [31:0] alu_b = use_imm ? imm : rs2_data;

    /* verilator lint_off UNUSEDSIGNAL */
    wire alu_zero;
    /* verilator lint_on UNUSEDSIGNAL */

    alu my_alu (
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_ctrl),
        .result(alu_out),
        .zero(alu_zero)
    );

    assign debug_pc = pc;
    assign debug_instr = instr;
    assign debug_alu_out = alu_out;

endmodule
