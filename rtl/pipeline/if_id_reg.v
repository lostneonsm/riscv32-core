module if_id_reg (
    input  wire        clk,
    input  wire         rst,
    input  wire         stall,
    input  wire         flush,
    input  wire [31:0] pc_current,
    input  wire [31:0] instr,
    output reg  [31:0] pc_if_id,
    output reg  [31:0] instr_if_id
);

    always @(posedge clk) begin
        if (rst) begin
            pc_if_id    <= 32'b0;
            instr_if_id <= 32'h00000013;  // NOP: ADDI x0, x0, 0
        end
        else if (stall) begin
            // do nothing -- registers naturally hold their current values
        end
        else if (flush) begin
            pc_if_id    <= 32'b0;
            instr_if_id <= 32'h00000013;  // NOP: ADDI x0, x0, 0
        end
        else begin
            pc_if_id    <= pc_current;
            instr_if_id <= instr;
        end
    end

endmodule
