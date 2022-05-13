#Inject at 0x800001B1
head:
    .set FLAG, 0x1c0
    .set CTRL, 0x1c1
    .set INIT_CTRL, 0x1c2
    .set ITEM, 0x1c3
    .set COIN_AMOUNT, 0x1c4
    .set DEFAULT_SPEED, 0x1d0
    .set MODIFIED_SPEED, 0x1d4
    .set ONE_PERCENT, 0x1d8
    .set ONE_PERCENT_OF_DEFAULT_SPEED, 0x1dc
    .set USED, 1
    .set UNUNSED, 0
    .set ITEM_BLOOPER, 0xC

    .set MAX_COINS, 0x41200000

    .set F_ONE, 0x1c8
    .set F_FOUR, 0x1cc

    .set FCONST, 0x1bc

    .set ONE_FLOAT, 0x3F800000
    .set PLAYER, 0x809BD110
    lis r12, 0x8000 #prepare r12 for addreses

    lbz r11, INIT_CTRL(r12) #load init byte

    cmpwi r11, 0

    #if init byte is 0, skip execution
    beq end 

    lbz r11, CTRL(r12)

    cmpwi r11, USED

    beq end
    #backup registers

    lis r11, MAX_COINS@ha
    ori r11, r11, MAX_COINS@l

    stw r11, FCONST(r12)


    lis r11, ONE_FLOAT@ha

    stw r11, FCONST+4(r12)


    stfs f1, F_ONE(r12)
    stfs f4, F_FOUR(r12)

    lis r11, 0x3c23
    ori r11, r11, 0xd70a
    #r11 = 0.01
    lfs f1, COIN_AMOUNT(r12)
    stw r11, ONE_PERCENT(r12)

    lbz r11, ITEM(r12) #load item

    cmpwi r11, ITEM_BLOOPER

    beq hasBlooper #go to hasblooper
    b reset #else

hasBlooper:
    
    lfs f4, FCONST(r12) #load max coins
    fcmpo cr1, f1, f4

    bge cr1, end

    lfs f4, FCONST+4(r12)

    fadds f1, f1, f4

    stfs f1, COIN_AMOUNT(r12)

    b set


reset:
    li r11, UNUNSED
    stb r11, CTRL(r12)
    stb r11, FLAG(r12)
    b else

else:

    lbz r11, DEFAULT_SPEED(r12) #load default speed as byte in r11

    cmpwi r11, 0 #stop execution if DS[0] == 0

    beq end
    b set

set:
    li r11, USED
    stb r11, CTRL(r12)

    lis r11, 0
    ori r11, r11, 0

    lfs f2, ONE_PERCENT(r12)

    lfs f3, DEFAULT_SPEED(r12)

    fmuls f2, f2, f3 #f2 = OPDS, f3 is free

    fmuls f3, f1, f2 #f3 & f2 = free

    lfs f2, DEFAULT_SPEED(r12)

    fadds f3, f3, f2

    lis r3, PLAYER@ha
    lwz r3, PLAYER@l(r3) #PlayerHolder
    lwz r3, 0x20(r3) #players
    lwz r3, 0(r3) #player[0]
    lwz r3, 0x14(r3) #playerSub10
    stfs f1, 0x20(r3) #vehicleSpeed



end:
    #restore registers

    lfs f1, F_ONE(r12)
    lfs f4, F_FOUR(r12)