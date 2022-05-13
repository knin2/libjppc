head:
	.set RAND, 0x80555464
	.macro random range #int random(int range)
		lis r12, RAND@h
		ori r12, r12, RAND@l
		lwz r11, 0(r12)
		cmpwi r11, 0
		beq end
		mtctr r12 #Random *rand = new Random();
		bctrl
		lis r12, 0x8000
		ori r12, r12, 0x6B0
		stw r3, 0(r12)
	.endm
	random 3
end: