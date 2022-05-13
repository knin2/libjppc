head:
	.set s_instance, 0x809bd110
	.set SAVE, 0x1B0
	lis r12, s_instance@h
	ori r12, r12, s_instance@l
	lwz r12, 0(r12) #PlayerHolder holder;
	lbz r10, 0x24(r12) #Player Count
	cmpw r11, r10
	blt loop
	b after
	loop:
		lwz r12, 0x20 (r12) #Player[] p;
		mulli r3, r11, 4 #r3 = i * 4;
		add r12, r3, r12 #r3 -> (Player[]) += r12;
		lwz r12, 0(r12) #Player c_p = p[i];
		lwz r12, 0(r12) #PlayerPointers p_ptr = current.pointers;
		lwz r12, 0x8(r12) #PlayerGraphics gfx;
		lwz r12, 0x90(r12) #PlayerPhysicsHolder phy = gfx.playerPhysicsHolder;
		lfs f2, 0x1C(r12) #float y = phy.position.y;
		lis r12, 0x8000
		mulli r5, r11, 4
		mulli r10, r9, 0x100
		addi r10, r10, SAVE
		add r5, r5, r10
		add r12, r5, r12
		stfs f2, 0(r12)
		addi r11, r11, 1
		b head
after:
	cmpwi r9, 0
	beq is_zero
	li r9, 0
	b next

is_zero:
	li r9, 1

next:
	li r11, 0