module control_unit (
    input wire [6:0] opcode,
    output reg reg_write,
    output reg alu_src,
    output reg [1:0] alu_src_a,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg jump,
    output reg jump_src,
    output reg [1:0] mem_to_reg,
    output reg [1:0] alu_op,
    output reg is_rtype
);

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
    // Default values
    reg_write = 1'b0;
    alu_src = 1'b0;
    alu_src_a = 2'b00;
    mem_read = 1'b0;
    mem_write = 1'b0;
    branch = 1'b0;
    jump = 1'b0;
    jump_src = 1'b0;
    mem_to_reg = 2'b00;
    alu_op = 2'b00;
    is_rtype = 1'b0;

    case (opcode) 
        OPC_RTYPE: begin
            reg_write =1'b1;
            alu_op = 2'b10;
            is_rtype = 1'b1;
        end
        OPC_ITYPE: begin
            reg_write = 1'b1;
            alu_src = 1'b1;
            alu_op = 2'b10;
        end
        OPC_LOAD: begin
            reg_write = 1'b1;
            alu_src = 1'b1;
            mem_read = 1'b1;
            mem_to_reg = 2'b01;
            alu_op = 2'b00;
        end
        OPC_JALR: begin
            reg_write = 1'b1;
            alu_src = 1'b1;
            jump = 1'b1;
            jump_src = 1'b1;
            mem_to_reg = 2'b10;
            alu_op = 2'b00;
        end
        OPC_STORE: begin
            alu_src = 1'b1;
            mem_write = 1'b1;
            alu_op = 2'b00;
        end
        OPC_BRANCH: begin
            branch = 1'b1;
            alu_op = 2'b01;
        end
        OPC_LUI: begin
            reg_write = 1'b1;
            alu_src = 1'b1;
            alu_src_a = 2'b10; // Use zero as the first operand
            alu_op = 2'b00;
        end
        OPC_AUIPC: begin
            reg_write = 1'b1;
            alu_src = 1'b1;
            alu_src_a = 2'b01; // Use PC as the first operand
            alu_op = 2'b00;
        end
        OPC_JAL: begin
            reg_write = 1'b1;
            jump = 1'b1;
            mem_to_reg = 2'b10;
            alu_op = 2'b00;
        end

        default: begin
            // Do nothing, all control signals are already set to default values
        end
    endcase
end

endmodule
