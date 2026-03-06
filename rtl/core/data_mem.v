module data_mem(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [2:0] funct3,
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

reg [31:0] mem [0:1023]; // 4KB of data memory (1024 words)

wire [31:0] word_addr = addr[31:2]; // Word-aligned address
wire [1:0] byte_offset = addr[1:0]; // Byte offset within the word

wire [31:0] current_word = mem[word_addr];

// ---- select the byte / halfword out of the current word (for reads)
wire [7:0] byte_sel = (byte_offset == 2'b00) ? current_word[7:0] :
                      (byte_offset == 2'b01) ? current_word[15:8] :
                      (byte_offset == 2'b10) ? current_word[23:16] :
                      current_word[31:24];

wire [15:0] half_sel = (byte_offset == 2'b00) ? current_word[15:0] : current_word[31:16]; // select the halfword out of the current word (for reads)

// ---- read logic
always @(*) begin
    if (mem_read) begin
        case (funct3)
            3'b000: read_data = {{24{byte_sel[7]}}, byte_sel}; // LB
            3'b001: read_data = {{16{half_sel[15]}}, half_sel}; // LH
            3'b010: read_data = current_word; // LW
            3'b100: read_data = {24'b0, byte_sel}; // LBU
            3'b101: read_data = {16'b0, half_sel}; // LHU
            default: read_data = current_word; // Default case
        endcase
    end
end

// write logic
always @(posedge clk) begin
    if (mem_write) begin
        case (funct3)
            3'b010: begin // SW
                mem[word_addr] <= write_data;
            end
            3'b000: begin // SB
                case (byte_offset)
                    2'b00: mem[word_addr][7:0] <= write_data[7:0];
                    2'b01: mem[word_addr][15:8] <= write_data[7:0];
                    2'b10: mem[word_addr][23:16] <= write_data[7:0];
                    2'b11: mem[word_addr][31:24] <= write_data[7:0];
                endcase
            end
            3'b001: begin // SH
                case (byte_offset) 
                    2'b00: mem[word_addr][15:0] <= write_data[15:0];
                    2'b10: mem[word_addr][31:16] <= write_data[15:0];
                    default: ; // Do nothing for unaligned halfword writes
                endcase
            end
            default: ; // Do nothing for unsupported funct3 values
        endcase
    end
end

endmodule
