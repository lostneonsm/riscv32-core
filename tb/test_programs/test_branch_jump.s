.section .text
.globl _start
_start:
    addi x1, x0, 5        # x1 = 5
    addi x2, x0, 5          # x2 = 5 (equal to x1)
    addi x3, x0, 8           # x3 = 8 (greater than x1)
    addi x10, x0, 0            # x10 = pass counter, increments on each correct branch

    beq  x1, x2, l1              # taken (5==5)
    jal  x0, fail                  # should be skipped
l1:
    addi x10, x10, 1

    bne  x1, x3, l2               # taken (5 != 8)
    jal  x0, fail
l2:
    addi x10, x10, 1

    blt  x1, x3, l3                # taken (5 < 8)
    jal  x0, fail
l3:
    addi x10, x10, 1

    bge  x3, x1, l4                 # taken (8 >= 5)
    jal  x0, fail
l4:
    addi x10, x10, 1

    bltu x1, x3, l5                  # taken (5 < 8 unsigned)
    jal  x0, fail
l5:
    addi x10, x10, 1

    bgeu x3, x1, l6                   # taken (8 >= 5 unsigned)
    jal  x0, fail
l6:
    addi x10, x10, 1

    # ---- jumps ----
    jal  x11, jtarget                  # x11 = return address (PC+4), jump to jtarget
    jal  x0, fail                        # should be skipped

jtarget:
    addi x10, x10, 1                       # counts as 7th success

    auipc x12, 0            # x12 = address of THIS instruction (PC + 0)
    jalr  x13, x12, 16        # target = x12 + 16 = this address + 16 bytes = 'end' label

    jal x0, end                                 # placeholder, see note below

fail:
    addi x20, x0, 999        # sentinel: if we ever land here, something's wrong

end:
    lui   x14, 0x12345         # x14 = 0x12345000
    auipc x15, 0x1               # x15 = PC + 0x1000
