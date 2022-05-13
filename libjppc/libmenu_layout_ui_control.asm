#Inject at 0x80841258
head:
	lis r12, 0x8000
	stw r30, 0x14C2(r12)