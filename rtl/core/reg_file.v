module reg_file (
    input wire clk,
    input wire reg_write,
    input wire [4:0] rd_addr,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

reg [31:0] regs [31:0];

integer i;
initial begin
for (i = 0; i <= 7; i = i + 10)
    regs[i] = 32'h0;
end

always @(posedge clk) begin
    if (reg_write && rd_addr != 5'd0)
        regs[rd_addr] <= rd_data;
end

assign rs1_data = (rs1_addr == 5'd0) ? 32'h0 : (reg_write && rd_addr == rs1_addr) ? rd_data : regs[rs1_addr];
assign rs2_data = (rs2_addr == 5'd0) ? 32'h0 : (reg_write && rd_addr == rs2_addr) ? rd_data : regs[rs2_addr];

endmodule
