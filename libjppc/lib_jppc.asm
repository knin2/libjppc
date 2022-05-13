#LIBJPPC - CODED BY JAWA 3/5/2022

#REGISTERS

.macro backup_cr
	mfcr r11
	lis r12, 0x8000
	stw r11, 0x17B0(r12)
	li r12, 0
	li r11, 0
.endm

.macro restore_cr
	lis r12, 0x8000
	lwz r11, 0x17B0(r12)
	mtctr r11
	li r12, 0
	li r11, 0
.endm

#STACK

.macro push_stack
	stwu sp,-0x80 (sp) #Push stack, make space for 29 registers
	stmw r3, 0x8 (sp)
	backup_cr
.endm

.macro pop_stack
	lmw r3, 0x8 (sp)
	addi sp, sp, 0x80 #Pop stack
	restore_cr
.endm

#FUNCTIONS
.macro call addr
	lis r12, \addr@h
	ori r12, r12, \addr@l
	mtctr r12
	bctr
.endm

.macro call_r addr
	lis r12, \addr@h
	ori r12, r12, \addr@l
	mtctr r12
	bctrl
.endm