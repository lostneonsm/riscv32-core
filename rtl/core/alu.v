// ============================================================
// alu.v -- Arithmetic Logic Unit
// Pure combinational: given two operands and an operation select signal, produces a result (and a zero flag, used by
// branch instructions to decide whether to take the branch).

// alu_ctrl encoding (must match alu_control.v exactly):
//   4'b0000 = ADD
//   4'b0001 = SUB
//   4'b0010 = AND
//   4'b0011 = OR
//   4'b0100 = XOR
//   4'b0101 = SLL
//   4'b0110 = SRL
//   4'b0111 = SRA
//   4'b1000 = SLT   (signed less-than)
//   4'b1001 = SLTU  (unsigned less-than)

module alu (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] alu_ctrl,
    output reg [31:0] result,
    output wire zero
);

wire [4:0] shamt = operand_b[4:0]; // Shift amount is the lower 5 bits of operand_b

always @(*) begin
    case (alu_ctrl)
        4'b0000: result = operand_a + operand_b; // ADD
        4'b0001: result = operand_a - operand_b; // SUB
        4'b0010: result = operand_a & operand_b; // AND
        4'b0011: result = operand_a | operand_b; // OR
        4'b0100: result = operand_a ^ operand_b; // XOR
        4'b0101: result = operand_a << shamt;    // SLL
        4'b0110: result = operand_a >> shamt;    // SRL
        4'b0111: result = $signed(operand_a) >>> shamt; // SRA (arthmetic right shift)
        4'b1000: result = ($signed(operand_a) <  $signed(operand_b)) ? 32'd1 : 32'd0; // SLT
        4'b1001: result = (operand_a < operand_b) ? 32'd1 : 32'd0; // SLTU
        default: result = 32'd0; // Default to zero for safety
    endcase
end

assign zero = (result == 32'd0);

endmodule
