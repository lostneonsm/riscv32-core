// ============================================================
// instr_mem.v -- Instruction Memory
// Read-only, combinational. Loaded at simulation start from a
// hex file via $readmemh. Indexed by WORD, not byte -- so the incoming byte address (from PC) has its bottom 2 bits dropped before being used as an array index.

module instr_mem (
    input wire [31:0] mem_addr,
    output wire [31:0] instr
);

reg [31:0] mem [0:1023]; // 4KB of instruction memory (1024 words)

initial begin
    $readmemh("/home/rnii/riscv_cpu/tb/test_programs/test_load_use.hex", mem);
end

assign instr = mem[mem_addr[31:2]]; // Drop the bottom 2 bits to index by word

endmodule
