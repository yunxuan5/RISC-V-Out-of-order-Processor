.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.


	# RAW Hazard example:
	addi x5, x0, 10      # x5 = 10
	add x6, x5, x5       # x6 = 20, depends on x5 from the previous instruction

	# WAR Hazard example (Note: Typically resolved by compiler scheduling, illustrated for concept):
	addi x7, x0, 15      # x7 = 15
	addi x8, x0, 5       # x8 = 5
	add x9, x7, x8       # x9 = 20, reading x7 and x8 before they are written by subsequent instructions

	# WAW Hazard example:
	addi x10, x0, 4      # x10 = 4
	addi x10, x10, 1     # x10 = 5, writing to x10 again before the previous write is complete

	# Control Hazard example:
	beq x0, x0, L1       # Always taken branch to L1
	nop                  # Delay slot (in architectures without branch prediction)
	L1: addi x11, x0, 2  # x11 = 2

	# Structural Hazard example:
	# Assuming a hypothetical scenario where the ALU and load/store units cannot operate simultaneously
	lw x12, 0(x2)        # Load word from memory into x12
	addi x13, x12, 1     # x13 = x12 + 1, immediate after load might cause structural hazard in some designs

	# Load-Use Data Hazard example:
	lw x14, 4(x2)        # Load word from memory into x14
	add x15, x14, x5     # x15 = x14 + x5, depends directly on the result of the load

	# Combining control and data hazards:
	jal x16, skip        # Jump to 'skip', setting x16 to return address
	addi x17, x16, 4     # Directly after a jump, uses x16 which just got written
	skip: nop

	# Test for simultaneous write and read (simulating a WAR hazard, though not common in RISC-V due to its pipeline design):
	addi x18, x0, 3      # x18 = 3
	sw x18, 12(x2)       # Store x18 to memory, assuming x2 is a base address
	lw x19, 12(x2)       # Load into x19 what was just stored, could be seen as WAR in a different context

	# Addressing memory hazards:
	lw x20, 16(x2)       # Load word from memory into x20
	sw x20, 20(x2)       # Store x20 to a new memory location, back-to-back memory ops might cause structural hazards

	# Ensuring all hazard types are covered, each instruction set aims to test a specific type of hazard.


    # Add your own test cases here!

    slti x0, x0, -256 # this is the magic instruction to end the simulation
