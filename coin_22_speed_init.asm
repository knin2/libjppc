head:
	#80571CA4

    #default instruction
    lfs	f1, 0x0018 (r3)
    .set INIT_CTRL, 0x1c4
    .set DEFAULT_SPEED, 0x1d0

    lis r12, 0x8000

    li r11, 1
    stb r11, INIT_CTRL(r12)

    stfs f1, DEFAULT_SPEED(r12)