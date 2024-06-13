.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    addi x1, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x2, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x4, x0, 10  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x5, x0, 6  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x6, x0, 3  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x7, x0, 16  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x8, x0, 15  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x9, x0, 7  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x10, x0, 13  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3, x1, 8  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    add x8, x1, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x6, x2, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    andi x6, x4, 12  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    and x6, x2, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    or x2, x3, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    ori x2, x4, 1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slt x5, x6, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slti x7, x9, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x4, x8, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x3, x6, x9  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srli x4, x10, 6  # x9 <= x12 srli 1
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srl x4, x1, x6  # x9 <= x12 srli 1
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srai x7, x6, 3  # x3 <= x2 srai 10
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    xori x7, x6, 3  # x3 <= x2 srai 10
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    xor x7, x6, x3  # x3 <= x2 srai 10
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sltiu x7, x9, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sltu x7, x9, x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slli x5, x6, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sll x5, x6, x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    lui x5,  3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    auipc x5,  0  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
andi x6, x4, 12  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    and x6, x2, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    or x2, x3, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    ori x2, x4, 1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slt x5, x6, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slti x7, x9, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x4, x8, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x3, x6, x9  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srli x4, x10, 6  # x9 <= x12 srli 1
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srl x4, x1, x6  # x9 <= x12 srli 1
    addi x1, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x2, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x4, x0, 10  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x5, x0, 6  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x6, x0, 3  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x7, x0, 16  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x8, x0, 15  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x9, x0, 7  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x10, x0, 13  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3, x1, 8  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    add x8, x1, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x6, x2, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    andi x6, x4, 12  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    and x6, x2, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    or x2, x3, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    ori x2, x4, 1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slt x5, x6, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slti x7, x9, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x4, x8, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x3, x6, x9  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srli x4, x10, 6  # x9 <= x12 srli 1
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srl x4, x1, x6  # x9 <= x12 srli 1
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srai x7, x6, 3  # x3 <= x2 srai 10
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    xori x7, x6, 3  # x3 <= x2 srai 10
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    xor x7, x6, x3  # x3 <= x2 srai 10
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sltiu x7, x9, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sltu x7, x9, x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slli x5, x6, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sll x5, x6, x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    lui x5,  3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    auipc x5,  0  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3,  x0, 36  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sub x5,  x5 ,x3  # x7 <= x2 slt x8
andi x6, x4, 12  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    and x6, x2, x3  # x3 <= x1 + 8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    or x2, x3, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    ori x2, x4, 1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slt x5, x6, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    slti x7, x9, 3  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x4, x8, x1  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    sra x3, x6, x9  # x7 <= x2 slt x8
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srli x4, x10, 6  # x9 <= x12 srli 1
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    srl x4, x1, x6  # x9 <= x12 srli 1

    # Add your own test cases here!

    slti x0, x0, -256 # this is the magic instruction to end the simulation
