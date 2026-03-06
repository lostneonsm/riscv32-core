module imm_gen (
    input wire [31:0] instr,
    output reg [31:0] imm_out
);

wire [6:0] opcode = instr[6:0];

localparam OPC_RTYPE  = 7'b0110011;  // ADD, SUB, AND, OR, ...      -> no immediate
localparam OPC_ITYPE  = 7'b0010011;  // ADDI, ANDI, SLTI, ...       -> I-type
localparam OPC_LOAD   = 7'b0000011;  // LW, LH, LB, ...             -> I-type
localparam OPC_JALR   = 7'b1100111;  // JALR                        -> I-type
localparam OPC_STORE  = 7'b0100011;  // SW, SH, SB                  -> S-type
localparam OPC_BRANCH = 7'b1100011;  // BEQ, BNE, BLT, ...          -> B-type
localparam OPC_LUI    = 7'b0110111;  // LUI                         -> U-type
localparam OPC_AUIPC  = 7'b0010111;  // AUIPC                       -> U-type
localparam OPC_JAL    = 7'b1101111;  // JAL                         -> J-type

always @(*) begin
    case (opcode)

        // ---------------------------------------------------
        // I-type: ADDI, loads, JALR
        // Immediate lives in instr[31:20]
        OPC_ITYPE, OPC_LOAD, OPC_JALR: begin
            imm_out = {{20{instr[31]}}, instr[31:20]};
        end

        // ---------------------------------------------------
        // S-type: SW, SH, SB
        // Immediate is SPLIT: imm[11:5] in instr[31:25], imm[4:0]  in instr[11:7]
        OPC_STORE: begin
            imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        end

        // ---------------------------------------------------
        // B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
        // Bits are scrambled AND imm[0] is always 0 (not stored in the encoding at all -- branch targets are even).
        // Bit locations:
        //   instr[31]   = imm[12]
        //   instr[30:25]= imm[10:5]
        //   instr[11:8] = imm[4:1]
        //   instr[7]    = imm[11]
        OPC_BRANCH: begin
            imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
        end

        // ---------------------------------------------------
        // U-type: LUI, AUIPC
        // Immediate occupies the TOP 20 bits directly.
        // No sign-extension needed in the usual sense --just fill the bottom 12 bits with zero.
        OPC_LUI, OPC_AUIPC: begin
            imm_out = {instr[31:12], 12'b0}; 
        end

        // ---------------------------------------------------
        // J-type: JAL
        // Bits are scrambled similarly to B-type, but for a 20-bit range (bigger jump distance), imm[0] also implicitly 0.
        //   instr[31]    = imm[20]
        //   instr[30:21] = imm[10:1]
        //   instr[20]    = imm[11]
        //   instr[19:12] = imm[19:12]
        OPC_JAL: begin
            imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        end

        // ---------------------------------------------------
        // R-type has no immediate -- output doesn't matter, but zero is a safe default.
        OPC_RTYPE: begin
            imm_out = 32'b0;
        end

        default: begin
            imm_out = 32'b0;
        end
    endcase
end

endmodule
