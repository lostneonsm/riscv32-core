// forwarding_unit.v -- resolves RAW hazards by detecting when
// the EX-stage instruction needs a value that's already been
// computed (sitting in EX/MEM or MEM/WB) but not yet written
// back to the register file.
//
// forward_a / forward_b encoding:
//   2'b00 = no forwarding needed -- use rs1_data_id_ex / rs2_data_id_ex as-is
//   2'b01 = forward from EX/MEM stage (alu_result_ex_mem)
//   2'b10 = forward from MEM/WB stage (the WB-stage writeback value)

module forwarding_unit (
    input  wire [4:0] rs1_addr_id_ex,
    input  wire [4:0] rs2_addr_id_ex,

    input  wire [4:0] rd_addr_ex_mem,
    input  wire       reg_write_ex_mem,

    input  wire [4:0] rd_addr_mem_wb,
    input  wire       reg_write_mem_wb,

    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

    always @(*) begin
        // ---- forward_a: check rs1 ----
        // EX/MEM check has priority -- it's the MORE RECENT result.
        if (reg_write_ex_mem && (rd_addr_ex_mem != 5'd0) && (rd_addr_ex_mem == rs1_addr_id_ex))
            forward_a = 2'b01;
        else if (reg_write_mem_wb && (rd_addr_mem_wb != 5'd0) && (rd_addr_mem_wb == rs1_addr_id_ex))
            forward_a = 2'b10;
        else
            forward_a = 2'b00;

        // ---- forward_b: check rs2, same logic ----
        if (reg_write_ex_mem && (rd_addr_ex_mem != 5'd0) && (rd_addr_ex_mem == rs2_addr_id_ex))
            forward_b = 2'b01;
        else if (reg_write_mem_wb && (rd_addr_mem_wb != 5'd0) && (rd_addr_mem_wb == rs2_addr_id_ex))
            forward_b = 2'b10;
        else
            forward_b = 2'b00;
    end

endmodule
