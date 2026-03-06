// alu_ctrl encoding (you can change this, just keep alu.v consistent with whatever you pick):
//   4'b0000 = ADD
//   4'b0001 = SUB
//   4'b0010 = AND
//   4'b0011 = OR
//   4'b0100 = XOR
//   4'b0101 = SLL   (shift left logical)
//   4'b0110 = SRL   (shift right logical)
//   4'b0111 = SRA   (shift right arithmetic)
//   4'b1000 = SLT   (set less than, signed)
//   4'b1001 = SLTU  (set less than, unsigned)

module alu_control (
    input wire  [1:0] alu_op,
    input wire [2:0] funct3,
    input wire funct7_bit5,
    input wire is_rtype,
    output reg [3:0] alu_ctrl
);

always @(*) begin
    case (alu_op)
        2'b00: alu_ctrl = 4'b0000; // For load/store instructions, use ADD

        2'b01: begin // For branch instructions, use SUB
            case (funct3)
                3'b000, 3'b001: alu_ctrl = 4'b0001; // BEQ, BNE -> SUB
                3'b100, 3'b101: alu_ctrl = 4'b1000; // BLT, BGE -> SLT
                3'b110, 3'b111: alu_ctrl = 4'b1001; // BLTU, BGEU -> SLTU
                default: alu_ctrl = 4'b0001; // Default to SUB for safety
            endcase
        end 

        2'b10: begin
            case (funct3)
                3'b000: begin
                    if (is_rtype)
                        alu_ctrl = funct7_bit5 ? 4'b0001 : 4'b0000; // SUB if funct7[5] is 1, else ADD
                    else
                        alu_ctrl = 4'b0000; // ADD for I-type instructions
                end
                3'b001: alu_ctrl = 4'b0101;
                3'b010: alu_ctrl = 4'b1000;
                3'b011: alu_ctrl = 4'b1001;
                3'b100: alu_ctrl = 4'b0100;
                3'b101: alu_ctrl = funct7_bit5 ? 4'b0111 : 4'b0110; // SRA if funct7[5] is 1, else SRL
                3'b110: alu_ctrl = 4'b0011; // OR
                3'b111: alu_ctrl = 4'b0010; // AND
                default: alu_ctrl = 4'b0000; // Default to ADD for safety
            endcase
        end

        default: alu_ctrl = 4'b0000; // Default to ADD for safety
    endcase
end

endmodule
