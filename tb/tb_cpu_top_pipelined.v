

`timescale 1ns/1ps

module tb_cpu_top_pipelined;

    reg clk;
    reg rst;

    cpu_top_pipelined dut (
        .clk (clk),
        .rst (rst)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer i;

    initial begin
        rst = 1;
        #12;
        rst = 0;

        // a bit more headroom than the single-cycle testbench,
        // since the pipeline takes a few extra cycles to drain
        // after the last instruction is fetched
        #650;

        $display("---- Final register values (pipelined) ----");
        for (i = 1; i < 32; i = i + 1) begin
            $display("x%0d = %0d (0x%0h)", i, $signed(dut.rf_inst.regs[i]), dut.rf_inst.regs[i]);
        end

        $finish;
    end

    initial begin
        $dumpfile("cpu_wave_pipelined.vcd");
        $dumpvars(0, tb_cpu_top_pipelined);
    end

endmodule
