module mem_wb_reg (
    input  wire        clk,
    input  wire         rst,
    input  wire         stall,
    input  wire         flush,

    // ---- control signals still needed for WB ----
    input  wire        reg_write_in,
    input  wire [1:0]  mem_to_reg_in,

    // ---- the three possible writeback data sources ----
    input  wire [31:0] alu_result_in,     // for ALU-result instructions
    input  wire [31:0] mem_read_data_in,   // for LW/LB/LH/etc (just computed by data_mem in MEM stage)
    input  wire [31:0] pc_plus4_in,         // for JAL/JALR

    input  wire [4:0]  rd_addr_in,      // destination register

    // ---- latched outputs ----
    output reg         reg_write_mem_wb,
    output reg  [1:0]  mem_to_reg_mem_wb,
    output reg  [31:0] alu_result_mem_wb,
    output reg  [31:0] mem_read_data_mem_wb,
    output reg  [31:0] pc_plus4_mem_wb,
    output reg  [4:0]  rd_addr_mem_wb
);

    always @(posedge clk) begin
        if (rst) begin
            reg_write_mem_wb     <= 1'b0;
            mem_to_reg_mem_wb    <= 2'b00;
            alu_result_mem_wb    <= 32'b0;
            mem_read_data_mem_wb <= 32'b0;
            pc_plus4_mem_wb      <= 32'b0;
            rd_addr_mem_wb       <= 5'b0;
        end
        else if (stall) begin
            // hold current values
        end
        else if (flush) begin
            reg_write_mem_wb     <= 1'b0;
            mem_to_reg_mem_wb    <= 2'b00;
            alu_result_mem_wb    <= 32'b0;
            mem_read_data_mem_wb <= 32'b0;
            pc_plus4_mem_wb      <= 32'b0;
            rd_addr_mem_wb       <= 5'b0;
        end
        else begin
            reg_write_mem_wb     <= reg_write_in;
            mem_to_reg_mem_wb    <= mem_to_reg_in;
            alu_result_mem_wb    <= alu_result_in;
            mem_read_data_mem_wb <= mem_read_data_in;
            pc_plus4_mem_wb      <= pc_plus4_in;
            rd_addr_mem_wb       <= rd_addr_in;
        end
    end

endmodule
