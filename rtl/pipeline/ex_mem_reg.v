module ex_mem_reg (
    input  wire        clk,
    input  wire         rst,
    input  wire         stall,
    input  wire         flush,

    // ---- control signals still needed for MEM and WB ----
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire [1:0]  mem_to_reg_in,

    // ---- data values ----
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,
    input  wire [4:0]  rd_addr_in,  
    input  wire [2:0]  funct3_in,
    input  wire [31:0] pc_plus4_in,
                                       
    // ---- latched outputs ----
    output reg         reg_write_ex_mem,
    output reg         mem_read_ex_mem,
    output reg         mem_write_ex_mem,
    output reg  [1:0]  mem_to_reg_ex_mem,

    output reg  [31:0] alu_result_ex_mem,
    output reg  [31:0] rs2_data_ex_mem,
    output reg  [4:0]  rd_addr_ex_mem,
    output reg  [2:0]  funct3_ex_mem,
    output reg  [31:0] pc_plus4_ex_mem
);

    always @(posedge clk) begin
        if (rst) begin
            reg_write_ex_mem   <= 1'b0;
            mem_read_ex_mem    <= 1'b0;
            mem_write_ex_mem   <= 1'b0;
            mem_to_reg_ex_mem  <= 2'b00;
            alu_result_ex_mem  <= 32'b0;
            rs2_data_ex_mem    <= 32'b0;
            rd_addr_ex_mem     <= 5'b0;
            funct3_ex_mem      <= 3'b0;
            pc_plus4_ex_mem    <= 32'b0;
        end
        else if (stall) begin
            // hold current values
        end
        else if (flush) begin
            reg_write_ex_mem   <= 1'b0;
            mem_read_ex_mem    <= 1'b0;
            mem_write_ex_mem   <= 1'b0;
            mem_to_reg_ex_mem  <= 2'b00;
            alu_result_ex_mem  <= 32'b0;
            rs2_data_ex_mem    <= 32'b0;
            rd_addr_ex_mem     <= 5'b0;
            funct3_ex_mem      <= 3'b0;
            pc_plus4_ex_mem    <= 32'b0;
        end
        else begin
            reg_write_ex_mem   <= reg_write_in;
            mem_read_ex_mem    <= mem_read_in;
            mem_write_ex_mem   <= mem_write_in;
            mem_to_reg_ex_mem  <= mem_to_reg_in;
            alu_result_ex_mem  <= alu_result_in;
            rs2_data_ex_mem    <= rs2_data_in;
            rd_addr_ex_mem     <= rd_addr_in;
            funct3_ex_mem      <= funct3_in;
            pc_plus4_ex_mem    <= pc_plus4_in;
        end
    end

endmodule
