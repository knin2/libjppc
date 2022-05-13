
head:
	#807E4B88
	lwz r0, 0x008C (r4) #default
	lis r12, 0x8000
	li r11, 0xc
	stb r11, 0x1C3(r12)