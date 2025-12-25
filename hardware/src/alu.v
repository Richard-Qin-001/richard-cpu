`include "defines.v"

module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_op,
    output reg [31:0] result,
    output wire zero
);

    assign zero = (result = 32'b0);

    always @(*) begin
        case (alu_op)
            `ALU_ADD: result = a + b;
            `ALU_SUB: result = a - b;
            `ALU_AND: result = a & b;
            `ALU_OR: result = a | b;
            `ALU_XOR: result = a ^ b;
            `ALU_SLL:  result = a << b[4:0];
            
            default: result = 32`b0;
        endcase
    end
    
endmodule
