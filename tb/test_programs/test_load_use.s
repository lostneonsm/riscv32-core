.section .text
.globl _start
_start:
    addi x1, x0, 100
    addi x2, x0, 42
    sw   x2, 0(x1)
    lw   x3, 0(x1)
    add  x4, x3, x3    # needs x3 immediately after the load -- load-use hazard
    