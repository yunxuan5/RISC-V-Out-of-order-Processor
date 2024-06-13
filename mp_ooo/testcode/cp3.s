.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    auipc x1, 0  #0c
    addi x1, x1, 40  # x1 <= 4
    addi x1, x1, 4  # x1 <= 4

    
    addi x25 , x0, 5

    sh x25,4(x1)
    lh x6, 4(x1)


target_label:
    slti x0, x0, -256 # this is the magic instruction to end the simulation  1c


