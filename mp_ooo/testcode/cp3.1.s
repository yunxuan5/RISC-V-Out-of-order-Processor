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

    addi x1, x1, 200  # x3 <= x1 + 8
    addi x4, x1, 12  # x4 <= 10
    sh x25,4(x1)
    lh x6, 4(x1)
    sh x25,8(x1)
    lh x14, 8(x1)
    sb x25,1(x1)
    sb x25,3(x1)
    lb x25,4(x1)
    sb x21,2(x1)

    addi x3, x1, 8  # x3 <= x1 + 8
    lh x4, 4(x1)
    and x6, x4, x3
    
    addi x1, x1, 20  # x1 <= 6000001c  0c

    
    slti x0, x0, -256 # this is the magic instruction to end the simulation  1c


