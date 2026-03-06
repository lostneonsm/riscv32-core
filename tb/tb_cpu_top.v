`timescale 1ns/1ps

module tb_cpu_top;

    reg clk;
    reg rst;

    cpu_top dut (
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

        // increased from #200 -- bigger test programs need more cycles.
        // rule of thumb: (number of instructions + a few extra) * 10ns
        #600;

        $display("---- Final register values ----");
        for (i = 1; i < 32; i = i + 1) begin
            $display("x%0d = %0d (0x%0h)", i, $signed(dut.rf_inst.regs[i]), dut.rf_inst.regs[i]);
        end

        $finish;
    end

    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, tb_cpu_top);
    end

endmodule
