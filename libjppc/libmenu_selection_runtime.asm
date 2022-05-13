#Inject at 0x807DFC14
head:
  lis r12, 0x8000
  ori r12, r12, 0x14C0
  stb r0, 0x0(r12)