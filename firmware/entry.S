.global entry
.section .text
.align 4

entry:
/* zero-initialize all registers */
addi x1, zero, 0
addi x2, zero, 0
addi x3, zero, 0
addi x4, zero, 0
addi x5, zero, 0
addi x6, zero, 0
addi x7, zero, 0
addi x8, zero, 0
addi x9, zero, 0
addi x10, zero, 0
addi x11, zero, 0
addi x12, zero, 0
addi x13, zero, 0
addi x14, zero, 0
addi x15, zero, 0
addi x16, zero, 0
addi x17, zero, 0
addi x18, zero, 0
addi x19, zero, 0
addi x20, zero, 0
addi x21, zero, 0
addi x22, zero, 0
addi x23, zero, 0
addi x24, zero, 0
addi x25, zero, 0
addi x26, zero, 0
addi x27, zero, 0
addi x28, zero, 0
addi x29, zero, 0
addi x30, zero, 0
addi x31, zero, 0

/* set stack pointer */

//lui sp, %hi(4*1024*1024)
//addi sp, sp, %lo(4*1024*1024)
la sp, _sp //load stack pointer from linker

/* push zeros on the stack for argc and argv */
/* (stack is aligned to 16 bytes in riscv calling convention) */
addi sp,sp,-16
sw zero,0(sp)
sw zero,4(sp)
sw zero,8(sp)
sw zero,12(sp)

/* Print "START\n" */
la t0, _print_addr

addi t1, zero, 0x53
sw t1, 0(t0) 

addi t1, zero, 0x54
sw t1, 0(t0)

addi t1, zero, 0x41
sw t1, 0(t0)

addi t1, zero, 0x52
sw t1, 0(t0)

addi t1, zero, 0x54
sw t1, 0(t0) 

addi t1, zero, 0x0a
sw t1, 0(t0) 

addi t0, zero, 0x0
addi t1, zero, 0x0

/* Load return address and go to main*/
la ra, exit
j main

.global exit
.section .text
.align 4
exit:
    la sp, _sp
    sw a0, -8(sp)

    /* Print "DONE\n" */
    la t0, _print_addr

    addi t1, zero, 0x44
    sw t1, 0(t0) 

    addi t1, zero, 0x4f
    sw t1, 0(t0)

    addi t1, zero, 0x4e
    sw t1, 0(t0)

    addi t1, zero, 0x45
    sw t1, 0(t0)

    addi t1, zero, 0x0a
    sw t1, 0(t0) 

    addi t0, zero, 0x0
    addi t1, zero, 0x0

    nop
    wfi

// some extra functions for multest.calling
.global hard_mul
.global hard_mulh
.global hard_mulhsu
.global hard_mulhu
.global hard_div
.global hard_divu
.global hard_rem
.global hard_remu

hard_mul:
	mul a0, a0, a1
	ret

hard_mulh:
	mulh a0, a0, a1
	ret

hard_mulhsu:
	mulhsu a0, a0, a1
	ret

hard_mulhu:
	mulhu a0, a0, a1
	ret

hard_div:
	div a0, a0, a1
	ret

hard_divu:
	divu a0, a0, a1
	ret

hard_rem:
	rem a0, a0, a1
	ret

hard_remu:
	remu a0, a0, a1
	ret