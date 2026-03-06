module pc (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [31:0] pc_next,
    output reg [31:0] pc_out
);

always @(posedge clk) begin
    if (rst)
        pc_out <= 32'h0;
    else if (!stall)
        pc_out <= pc_next;
end

endmodule
