module cpu_top_pipelined (
    input wire clk,
    input wire rst
);
    
    // IF STAGE Wires
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] instr_if;
    wire        pc_redirect_ex;
    wire [31:0] pc_redirect_target;

    // IF/ID REGISTER Wires
    wire [31:0] pc_id;
    wire [31:0] instr_id;

    // ID STAGE Wires
    wire [6:0]  opcode;
    wire [4:0]  rd_addr;
    wire [2:0]  funct3;
    wire [4:0]  rs1_addr;
    wire [4:0]  rs2_addr;
    wire        funct7_bit5;
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire        is_rtype;
    wire        branch;
    wire        jump;
    wire        jump_src;
    wire [1:0]  mem_to_reg;
    wire [1:0]  alu_op;
    wire [1:0]  alu_src_a;
    wire        stall;
    wire [31:0] imm;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // ID/EX REGISTER Wires
    wire        reg_write_id_ex;
    wire        alu_src_id_ex;
    wire        mem_read_id_ex;
    wire        mem_write_id_ex;
    wire        branch_id_ex;
    wire        jump_id_ex;
    wire        jump_src_id_ex;
    wire        is_rtype_id_ex;
    wire [1:0]  mem_to_reg_id_ex;
    wire [1:0]  alu_op_id_ex;
    wire [1:0]  alu_src_a_id_ex;
    wire [31:0] pc_id_ex;
    wire [31:0] rs1_data_id_ex;
    wire [31:0] rs2_data_id_ex;
    wire [31:0] imm_id_ex;
    wire [4:0]  rd_addr_id_ex;
    wire [4:0]  rs1_addr_id_ex;
    wire [4:0]  rs2_addr_id_ex;
    wire [2:0]  funct3_id_ex;
    wire        funct7_bit5_id_ex;

    // EX STAGE Wires
    wire [31:0] rd_data_wb;
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire [31:0] rs1_forwarded;
    wire [31:0] rs2_forwarded;
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] pc_plus4_ex;
    wire        branch_taken_ex;

    // EX/MEM REGISTER Wires
    wire        reg_write_ex_mem;
    wire        mem_read_ex_mem;
    wire        mem_write_ex_mem;
    wire [1:0]  mem_to_reg_ex_mem;
    wire [31:0] alu_result_ex_mem;
    wire [31:0] rs2_data_ex_mem;
    wire [31:0] pc_plus4_ex_mem;
    wire [4:0]  rd_addr_ex_mem;
    wire [2:0]  funct3_ex_mem;

    // MEM STAGE Wires
    wire [31:0] mem_read_data;

    // MEM/WB REGISTER Wires
    wire        reg_write_mem_wb;
    wire [1:0]  mem_to_reg_mem_wb;
    wire [31:0] alu_result_mem_wb;
    wire [31:0] mem_read_data_mem_wb;
    wire [31:0] pc_plus4_mem_wb;
    wire [4:0]  rd_addr_mem_wb;


    //  IF STAGE 
    assign pc_redirect_ex = jump_id_ex || branch_taken_ex;
    assign pc_redirect_target = (jump_id_ex && jump_src_id_ex) ? alu_result : (pc_id_ex + imm_id_ex);
    assign pc_next = pc_redirect_ex ? pc_redirect_target : (pc_current + 32'd4);

    pc pc_inst (
        .clk     (clk),
        .rst     (rst),
        .stall   (stall),
        .pc_next (pc_next),
        .pc_out  (pc_current)
    );

    instr_mem imem_inst (
        .mem_addr (pc_current),
        .instr    (instr_if)
    );

    //  IF/ID REGISTER 
    if_id_reg if_id_inst (
        .clk         (clk),
        .rst         (rst),
        .stall       (stall),
        .flush       (pc_redirect_ex),
        .pc_current  (pc_current),
        .instr       (instr_if),
        .pc_if_id    (pc_id),
        .instr_if_id (instr_id)
    );

    //  ID STAGE 
    assign opcode      = instr_id[6:0];
    assign rd_addr     = instr_id[11:7];
    assign funct3      = instr_id[14:12];
    assign rs1_addr    = instr_id[19:15];
    assign rs2_addr    = instr_id[24:20];
    assign funct7_bit5 = instr_id[30];

    hazard_unit hazard_inst (
        .mem_read_id_ex (mem_read_id_ex),
        .rd_addr_id_ex  (rd_addr_id_ex),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .stall          (stall)
    );

    control_unit ctrl_inst (
        .opcode      (opcode),
        .reg_write   (reg_write),
        .alu_src     (alu_src),
        .alu_src_a   (alu_src_a),
        .mem_read    (mem_read),
        .mem_write   (mem_write),
        .branch      (branch),
        .jump        (jump),
        .jump_src    (jump_src),
        .mem_to_reg  (mem_to_reg),
        .alu_op      (alu_op),
        .is_rtype    (is_rtype)
    );

    imm_gen imm_inst (
        .instr   (instr_id),
        .imm_out (imm)
    );

    reg_file rf_inst (
        .clk       (clk),
        .reg_write (reg_write_mem_wb),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr_mem_wb),
        .rd_data   (rd_data_wb),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    //  ID/EX REGISTER 
    id_ex_reg id_ex_inst (
        .clk               (clk),
        .rst               (rst),
        .stall             (1'b0),
        .flush             (pc_redirect_ex || stall),
        .reg_write_in      (reg_write),
        .alu_src_in        (alu_src),
        .alu_src_a_in      (alu_src_a),
        .mem_read_in       (mem_read),
        .mem_write_in      (mem_write),
        .branch_in         (branch),
        .jump_in           (jump),
        .jump_src_in       (jump_src),
        .mem_to_reg_in     (mem_to_reg),
        .alu_op_in         (alu_op),
        .is_rtype_in       (is_rtype),
        .pc_in             (pc_id),
        .rs1_data_in       (rs1_data),
        .rs2_data_in       (rs2_data),
        .imm_in            (imm),
        .rd_addr_in        (rd_addr),
        .rs1_addr_in       (rs1_addr),         
        .rs2_addr_in       (rs2_addr),          
        .funct3_in         (funct3),
        .funct7_bit5_in    (funct7_bit5),
        .reg_write_id_ex   (reg_write_id_ex),
        .alu_src_id_ex     (alu_src_id_ex),
        .alu_src_a_id_ex   (alu_src_a_id_ex),
        .mem_read_id_ex    (mem_read_id_ex),
        .mem_write_id_ex   (mem_write_id_ex),
        .branch_id_ex      (branch_id_ex),
        .jump_id_ex        (jump_id_ex),
        .jump_src_id_ex    (jump_src_id_ex),
        .mem_to_reg_id_ex  (mem_to_reg_id_ex),
        .alu_op_id_ex      (alu_op_id_ex),
        .is_rtype_id_ex    (is_rtype_id_ex),
        .pc_id_ex          (pc_id_ex),
        .rs1_data_id_ex    (rs1_data_id_ex),
        .rs2_data_id_ex    (rs2_data_id_ex),
        .imm_id_ex         (imm_id_ex),
        .rd_addr_id_ex     (rd_addr_id_ex),
        .rs1_addr_id_ex    (rs1_addr_id_ex),  
        .rs2_addr_id_ex    (rs2_addr_id_ex),  
        .funct3_id_ex      (funct3_id_ex),
        .funct7_bit5_id_ex (funct7_bit5_id_ex)
    );

    //  EX STAGE 
    assign rd_data_wb = (mem_to_reg_mem_wb == 2'b01) ? mem_read_data_mem_wb :
                        (mem_to_reg_mem_wb == 2'b10) ? pc_plus4_mem_wb :
                        alu_result_mem_wb;

    // ---- forwarding ----
    forwarding_unit fwd_inst (
        .rs1_addr_id_ex   (rs1_addr_id_ex),
        .rs2_addr_id_ex   (rs2_addr_id_ex),
        .rd_addr_ex_mem   (rd_addr_ex_mem),
        .reg_write_ex_mem (reg_write_ex_mem),
        .rd_addr_mem_wb   (rd_addr_mem_wb),
        .reg_write_mem_wb (reg_write_mem_wb),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    assign rs1_forwarded = (forward_a == 2'b01) ? alu_result_ex_mem :
                           (forward_a == 2'b10) ? rd_data_wb :
                           rs1_data_id_ex;

    assign rs2_forwarded = (forward_b == 2'b01) ? alu_result_ex_mem :
                           (forward_b == 2'b10) ? rd_data_wb :
                           rs2_data_id_ex;

    assign alu_operand_a = (alu_src_a_id_ex == 2'b01) ? pc_id_ex :
                           (alu_src_a_id_ex == 2'b10) ? 32'd0 :
                           rs1_forwarded;

    assign alu_operand_b = (alu_src_id_ex) ? imm_id_ex : rs2_forwarded;

    alu_control alu_ctrl_inst (
        .alu_op      (alu_op_id_ex),
        .funct3      (funct3_id_ex),
        .funct7_bit5 (funct7_bit5_id_ex),
        .is_rtype    (is_rtype_id_ex),
        .alu_ctrl    (alu_ctrl)
    );

    alu alu_inst (
        .operand_a (alu_operand_a),
        .operand_b (alu_operand_b),
        .alu_ctrl  (alu_ctrl),
        .result    (alu_result),
        .zero      (alu_zero)
    );

    assign pc_plus4_ex = pc_id_ex + 32'd4;

    assign branch_taken_ex = branch_id_ex && (
        (funct3_id_ex == 3'b000 &&  alu_zero)      ||
        (funct3_id_ex == 3'b001 && !alu_zero)      ||
        (funct3_id_ex == 3'b100 &&  alu_result[0]) ||
        (funct3_id_ex == 3'b101 && !alu_result[0]) ||
        (funct3_id_ex == 3'b110 &&  alu_result[0]) ||
        (funct3_id_ex == 3'b111 && !alu_result[0])
    );

    //  EX/MEM REGISTER 
    ex_mem_reg ex_mem_inst (
        .clk               (clk),
        .rst               (rst),
        .stall             (1'b0),
        .flush             (1'b0),
        .reg_write_in      (reg_write_id_ex),
        .mem_read_in       (mem_read_id_ex),
        .mem_write_in      (mem_write_id_ex),
        .mem_to_reg_in     (mem_to_reg_id_ex),
        .alu_result_in     (alu_result),
        .rs2_data_in       (rs2_forwarded),
        .rd_addr_in        (rd_addr_id_ex),
        .funct3_in         (funct3_id_ex),
        .pc_plus4_in       (pc_plus4_ex),
        .reg_write_ex_mem  (reg_write_ex_mem),
        .mem_read_ex_mem   (mem_read_ex_mem),
        .mem_write_ex_mem  (mem_write_ex_mem),
        .mem_to_reg_ex_mem (mem_to_reg_ex_mem),
        .alu_result_ex_mem (alu_result_ex_mem),
        .rs2_data_ex_mem   (rs2_data_ex_mem),
        .rd_addr_ex_mem    (rd_addr_ex_mem),
        .funct3_ex_mem     (funct3_ex_mem),
        .pc_plus4_ex_mem   (pc_plus4_ex_mem)
    );

    //  MEM STAGE 
    data_mem dmem_inst (
        .clk        (clk),
        .mem_read   (mem_read_ex_mem),
        .mem_write  (mem_write_ex_mem),
        .funct3     (funct3_ex_mem),
        .addr       (alu_result_ex_mem),
        .write_data (rs2_data_ex_mem),
        .read_data  (mem_read_data)
    );

    // MEM/WB REGISTER 
    mem_wb_reg mem_wb_inst (
        .clk               (clk),
        .rst               (rst),
        .stall             (1'b0),
        .flush             (1'b0),
        .reg_write_in      (reg_write_ex_mem),
        .mem_to_reg_in     (mem_to_reg_ex_mem),
        .alu_result_in     (alu_result_ex_mem),
        .mem_read_data_in  (mem_read_data),
        .pc_plus4_in       (pc_plus4_ex_mem),
        .rd_addr_in        (rd_addr_ex_mem),
        .reg_write_mem_wb     (reg_write_mem_wb),
        .mem_to_reg_mem_wb    (mem_to_reg_mem_wb),
        .alu_result_mem_wb    (alu_result_mem_wb),
        .mem_read_data_mem_wb (mem_read_data_mem_wb),
        .pc_plus4_mem_wb      (pc_plus4_mem_wb),
        .rd_addr_mem_wb       (rd_addr_mem_wb)
    );

endmodule
