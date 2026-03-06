module cpu_top (
    input wire clk,
    input wire rst
);


wire [31:0] pc_current;
wire [31:0] pc_next;
wire [31:0] instr;

wire [6:0]  opcode = instr[6:0];
wire [4:0]  rd_addr = instr[11:7];
wire [2:0]  funct3 = instr[14:12];
wire [4:0]  rs1_addr = instr[19:15];
wire [4:0]  rs2_addr = instr[24:20];
wire        funct7 = instr[30];

wire        reg_write, mem_read, mem_write, alu_src;
wire        branch, jump, jump_src;
wire [1:0]  mem_to_reg, alu_op, alu_src_a;      

wire [31:0] imm;

wire [31:0] rs1_data, rs2_data;
wire [31:0] rd_data;

wire [31:0] alu_operand_a, alu_operand_b;

wire [3:0]  alu_ctrl;
wire        is_rtype;


// Instantiate the PC module
pc pc_inst (
    .clk(clk),
    .rst(rst),
    .stall(1'b0),
    .pc_next(pc_next),
    .pc_out(pc_current)
);

// Instantiate the instruction memory module
instr_mem imem_inst (
    .mem_addr(pc_current),
    .instr(instr)
);

// Instantiate the control unit module
control_unit ctrl_inst (
    .opcode(opcode),
    .reg_write(reg_write),
    .alu_src(alu_src),
    .alu_src_a(alu_src_a),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .jump_src(jump_src),
    .mem_to_reg(mem_to_reg),
    .alu_op(alu_op),
    .is_rtype(is_rtype)
);

// Instantiate the immediate generator module
imm_gen imm_inst (
    .instr(instr),
    .imm_out(imm)
);

// Instantiate the register file module
reg_file rf_inst (
    .clk(clk),
    .reg_write(reg_write),
    .rd_addr(rd_addr),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .rd_data(rd_data)
);

// Instantiate the ALU control module
alu_control _actrl_inst (
    .alu_op(alu_op),
    .funct3(funct3),
    .funct7_bit5(funct7),
    .alu_ctrl(alu_ctrl),
    .is_rtype(is_rtype)
);

wire [31:0] alu_result;
wire        alu_zero;

// Instantiate the ALU module
alu alu_inst (
    .operand_a(alu_operand_a),
    .operand_b(alu_operand_b),
    .alu_ctrl(alu_ctrl),
    .result(alu_result),
    .zero(alu_zero)
);

wire [31:0] mem_read_data;

// Instantiate the data memory module
data_mem dmem_inst (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .funct3(funct3),
    .addr(alu_result),
    .write_data(rs2_data),
    .read_data(mem_read_data)
);

wire branch_taken;

assign branch_taken = branch && (
    (funct3 == 3'b000 &&  alu_zero)      ||  // BEQ
    (funct3 == 3'b001 && !alu_zero)      ||  // BNE
    (funct3 == 3'b100 &&  alu_result[0]) ||  // BLT
    (funct3 == 3'b101 && !alu_result[0]) ||  // BGE
    (funct3 == 3'b110 &&  alu_result[0]) ||  // BLTU
    (funct3 == 3'b111 && !alu_result[0])     // BGEU
);

assign pc_next = (jump && jump_src)   ? alu_result :            // JALR: target = rs1+imm (already in alu_result)
                 (jump)                ? (pc_current + imm) :   // JAL: target = PC+imm
                 (branch_taken)        ? (pc_current + imm) :   // taken branch: target = PC+imm
                 (pc_current + 32'd4);                          // default: next instruction

assign alu_operand_a = (alu_src_a == 2'b01) ? pc_current : (alu_src_a == 2'b10) ? 32'd0 : rs1_data;
assign alu_operand_b = (alu_src) ? imm : rs2_data;

assign rd_data = (mem_to_reg == 2'b01) ? mem_read_data : (mem_to_reg == 2'b10) ? (pc_current + 32'd4) : alu_result;

endmodule
