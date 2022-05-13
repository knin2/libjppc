head:
	.set ISFS_CreateFile, 0x8016abd4 #(string* file, int[,4] perm)
	.set ISFS_Open, 0x8016adbc #(string* file, int mode = 3) -> int fd: r3
	.set ISFS_Write, 0x8016b220 #(int fd, void* buf, int size) -> int read: r3
	.set ISFS_Close, 0x8016b2e4 #(int fd)
	.set strcmp, 0x8001273c #(string *s, string*s0) -> r3

	stwu sp,-0x80 (sp) #Push stack, make space for 29 registers
	stmw r3, 0x8 (sp)


	lis r12, 0x8000


	lwz r12, 0x3B0(r12) #string* file;
	cmpwi r12, 0
	beq skip


	li r11, 0
	while:
		add r10, r11, r12 #char *cptr;

		addi r11, r11, 1

		lbz r9, 0(r10) #char c;
		cmpwi r9, 0
		beq end #if c == 0x00 end loop

		#save char
		lis r10, 0
		addi r3, r11, 0x3B4 
		lis r10, 0x8000
		add r10, r10, r3 
		stb r9, 0(r10)

		b while #else continue loop
	end:
		addi r11, r11, 1 #r11 = strlen(file);
		lis r12, 0x8000
		stb r11, 0x3B4(r12) #store string length
	.macro exec addr
		lis r0, \addr@ha
		ori r0, r0, \addr@l
		mtctr r0
		bctrl
	.endm

	lis r3, 0x8000
	ori r3, r3, 0x3B0
	lis r4, 0x8000
	ori r4, r4, 0x4B0
	exec strcmp # -> r3
	cmpwi r3, 0
	bne write
	b skip
write:
	#prepare args
	lis r3, 0x8000
	ori r3, r3, 0x3B5
	mr r12, r3
	li r4, 0
	li r5, 3
	li r6, 3
	li r7, 3

	exec ISFS_CreateFile
	mr r3, r12
	li r4, 2

	exec ISFS_Open #file opened -> r3

	#prepare args
	mr r4, r12
	mr r5, r11
	exec ISFS_Write

	exec ISFS_Close
	lis r12, 0x8000
	lwz r12, 0x3B0(r12) #string* file;
	lis r11, 0x8000
	stw r12, 0x4B0(r11)
skip:

	lmw r3, 0x8 (sp)
	addi sp, sp, 0x80 #Pop stack