// ============================================================
// id_ex_reg.v -- ID/EX Pipeline Register
// Latches everything the EX stage (and later stages, since control signals ride along further too) needs, one cycle after decode.

module id_ex_reg (
    input  wire        clk,
    input  wire         rst,
    input  wire         stall,
    input  wire         flush,

    // ---- control signals from control_unit ----
    input  wire        reg_write_in,
    input  wire        alu_src_in,
    input  wire [1:0]  alu_src_a_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        jump_src_in,
    input  wire [1:0]  mem_to_reg_in,
    input  wire [1:0]  alu_op_in,
    input  wire        is_rtype_in,

    // ---- decoded values ----
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,

    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,

    input  wire [31:0] imm_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [2:0]  funct3_in,
    input  wire         funct7_bit5_in,

    // ---- latched outputs (same names, _id_ex suffix) ----
    output reg         reg_write_id_ex,
    output reg         alu_src_id_ex,
    output reg  [1:0]  alu_src_a_id_ex,
    output reg         mem_read_id_ex,
    output reg         mem_write_id_ex,
    output reg         branch_id_ex,
    output reg         jump_id_ex,
    output reg         jump_src_id_ex,
    output reg  [1:0]  mem_to_reg_id_ex,
    output reg  [1:0]  alu_op_id_ex,
    output reg         is_rtype_id_ex,

    output reg  [31:0] pc_id_ex,
    output reg  [31:0] rs1_data_id_ex,
    output reg  [31:0] rs2_data_id_ex,
    output reg  [4:0]  rs1_addr_id_ex,
    output reg  [4:0]  rs2_addr_id_ex,
    output reg  [31:0] imm_id_ex,
    output reg  [4:0]  rd_addr_id_ex,
    output reg  [2:0]  funct3_id_ex,
    output reg         funct7_bit5_id_ex
);

    always @(posedge clk) begin
        if (rst) begin
            reg_write_id_ex   <= 1'b0;
            alu_src_id_ex     <= 1'b0;
            alu_src_a_id_ex   <= 2'b00;
            mem_read_id_ex    <= 1'b0;
            mem_write_id_ex   <= 1'b0;
            branch_id_ex      <= 1'b0;
            jump_id_ex        <= 1'b0;
            jump_src_id_ex    <= 1'b0;
            mem_to_reg_id_ex  <= 2'b00;
            alu_op_id_ex      <= 2'b00;
            is_rtype_id_ex    <= 1'b0;
            pc_id_ex          <= 32'b0;
            rs1_data_id_ex    <= 32'b0;
            rs2_data_id_ex    <= 32'b0;
            rs1_addr_id_ex    <= 5'b0;
            rs2_addr_id_ex    <= 5'b0;
            imm_id_ex         <= 32'b0;
            rd_addr_id_ex     <= 5'b0;
            funct3_id_ex      <= 3'b0;
            funct7_bit5_id_ex <= 1'b0;
        end
        else if (stall) begin
            // hold current values -- do nothing
        end
        else if (flush) begin
            reg_write_id_ex   <= 1'b0;
            alu_src_id_ex     <= 1'b0;
            alu_src_a_id_ex   <= 2'b00;
            mem_read_id_ex    <= 1'b0;
            mem_write_id_ex   <= 1'b0;
            branch_id_ex      <= 1'b0;
            jump_id_ex        <= 1'b0;
            jump_src_id_ex    <= 1'b0;
            mem_to_reg_id_ex  <= 2'b00;
            alu_op_id_ex      <= 2'b00;
            is_rtype_id_ex    <= 1'b0;
            pc_id_ex          <= 32'b0;
            rs1_data_id_ex    <= 32'b0;
            rs2_data_id_ex    <= 32'b0;
            rs1_addr_id_ex    <= 5'b0;
            rs2_addr_id_ex    <= 5'b0;
            imm_id_ex         <= 32'b0;
            rd_addr_id_ex     <= 5'b0;
            funct3_id_ex      <= 3'b0;
            funct7_bit5_id_ex <= 1'b0;
        end
        else begin
            reg_write_id_ex   <= reg_write_in;
            alu_src_id_ex     <= alu_src_in;
            alu_src_a_id_ex   <= alu_src_a_in;
            mem_read_id_ex    <= mem_read_in;
            mem_write_id_ex   <= mem_write_in;
            branch_id_ex      <= branch_in;
            jump_id_ex        <= jump_in;
            jump_src_id_ex    <= jump_src_in;
            mem_to_reg_id_ex  <= mem_to_reg_in;
            alu_op_id_ex      <= alu_op_in;
            is_rtype_id_ex    <= is_rtype_in;
            pc_id_ex          <= pc_in;
            rs1_data_id_ex    <= rs1_data_in;
            rs2_data_id_ex    <= rs2_data_in;
            rs1_addr_id_ex    <= rs1_addr_in;
            rs2_addr_id_ex    <= rs2_addr_in;
            imm_id_ex         <= imm_in;
            rd_addr_id_ex     <= rd_addr_in;
            funct3_id_ex      <= funct3_in;
            funct7_bit5_id_ex <= funct7_bit5_in;
        end
    end

endmodule
