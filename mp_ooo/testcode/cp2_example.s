.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    addi x1, x0, 4  # x1 <= 4
    addi x0, x1, 4  # x1 <= 4
    
    addi x25 , x0, 5
    auipc x1, 0  #0c
    addi x1, x1, 2  # x3 <= x1 + 8
    addi x4, x1, 12  # x4 <= 10
    lh x8, 4(x1)
    sh x25,4(x1)
    lh x6, 4(x1)
    sh x25,2(x1)
    lh x14, 2(x1)
    sb x25,1(x1)
    sb x25,3(x1)
    lb x25,3(x1)
    sb x21,2(x1)
    lb x6, 2(x4)
    sb x23,8(x4)
    sw x24,6(x4)
    lw x6, 6(x4)
    sw x3, 10(x4)
    lw x7, 10(x4)
    addi x3, x1, 8  # x3 <= x1 + 8
    lh x4, 2(x1)
    and x6, x4, x3
    
    addi x1, x1, 20  # x1 <= 6000001c  0c
    sw x3, 2(x1)
    lw x7, 2(x1)
    addi x10, x0, 100
    
    jal x3,target
    # jalr x3 , x1,0   # 10
target:
    
    sw x3, 2(x1)
    lw x7, 2(x1)
    addi x9, x0, 1
    sub x10, x10, x9  # x1 <= 4
    addi x3, x1, 8  # x3 <= x1 + 8
    bne x10, x0, target
    # Add your own test cases here!

target_label:
    slti x0, x0, -256 # this is the magic instruction to end the simulation  1c


