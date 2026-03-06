.section .text
.globl _start
_start:
    # ---- fixed operands ----
    addi x1, x0, 12        # x1 = 12
    addi x2, x0, 5          # x2 = 5

    # ---- R-type ALU (x3-x12) ----
    add  x3,  x1, x2         # 17
    sub  x4,  x1, x2         # 7
    sll  x5,  x1, x2          # 384
    slt  x6,  x1, x2           # 0
    sltu x7,  x1, x2            # 0
    xor  x8,  x1, x2              # 9
    srl  x9,  x1, x2               # 0
    sra  x10, x1, x2                 # 0
    or   x11, x1, x2                  # 13
    and  x12, x1, x2                   # 4

    # ---- I-type ALU immediates (x13-x21) ----
    addi  x13, x1, 5        # 17
    slti  x14, x1, 5         # 0
    sltiu x15, x1, 5          # 0
    xori  x16, x1, 5           # 9
    ori   x17, x1, 5            # 13
    andi  x18, x1, 5             # 4
    slli  x19, x1, 2              # 48
    srli  x20, x1, 2               # 3
    srai  x21, x1, 2                # 3

    # ---- memory, all widths (x22-x28) ----
    addi x22, x0, 200        # base address
    addi x23, x0, -5           # value to store, negative to test sign-extend

    sb   x23, 0(x22)             # store byte
    lb   x24, 0(x22)              # -5, sign-extended
    lbu  x25, 0(x22)               # 251, zero-extended

    sh   x23, 4(x22)                 # store halfword
    lh   x26, 4(x22)                  # -5, sign-extended
    lhu  x27, 4(x22)                   # 65531, zero-extended

    sw   x23, 8(x22)                     # store word
    lw   x28, 8(x22)                      # -5
    