.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    auipc x5, 0
    JALR x4, x5, 20 
    addi x1, x1, 10  # x1 <= 4 08
    addi x2, x1, 4  # x1 <= 4 0c
    addi x3, x1, 20  # x1 <= 4 10
    addi x4, x1, 5  # x1 <= 4 14
    addi x5, x1, 30  # x1 <= 4
    addi x6, x1, 6  # x1 <= 4
    addi x7, x1, 40  # x1 <= 4
    addi x8, x1, 7  # x1 <= 4
    addi x9, x1, 50  # x1 <= 4

    jal x3, tag
    addi x6, x1, 6  # x1 <= 4
    addi x7, x1, 40  # x1 <= 4
    addi x8, x1, 7  # x1 <= 4
    addi x9, x1, 50  # x1 <= 4

tag:
    addi x11, x0, 10  # x1 <= 4
    addi x12, x0, 100  # x1 <= 4
    addi x11, x11, -1
    blt x11, x0, tag




 
    # Add your own test cases here!

    slti x0, x0, -256 # this is the magic instruction to end the simulation