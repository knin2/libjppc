#Inject at 0x8070ca04
head:
	lis r12, 0x8000
	stb r30, 0x14C1(r12)