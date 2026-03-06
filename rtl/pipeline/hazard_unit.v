// hazard_unit.v -- detects the ONE case forwarding can't fix:
// load-use hazard. If the instruction currently in EX stage is a LOAD, and the instruction currently in ID stage needs that
// load's result, we must stall for one cycle (the data doesn't exist yet -- it's only available after MEM stage runs).

module hazard_unit (
    input  wire        mem_read_id_ex,
    input  wire [4:0]  rd_addr_id_ex,

    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,

    output wire        stall
);

    assign stall = mem_read_id_ex &&
                   (rd_addr_id_ex != 5'd0) &&
                   ((rd_addr_id_ex == rs1_addr) || (rd_addr_id_ex == rs2_addr));

endmodule
