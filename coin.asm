head:
    .set FLAG, 0x1c0
    .set COIN_AMOUNT, 0x1c7
    .set ITEM, 0x1c8
    .set DEFAULT_SPEED, 0x1d0
    .set MODIFIED_SPEED, 0x1d4
    .set ONE_PERCENT, 0x1d8
    .set ONE_PERCENT_OF_DEFAULT_SPEED, 0x1dc
    .set USED, 1
    .set UNUNSED, 0



    lis r12, 0x8000
    lbz r11, ITEM(r12) #load item value
    
    .set ITEM_BLOOPER, 0xC
    li r10, ITEM_BLOOPER
    cmpw r11, r10


    #reset FLAG

    lis r12, 0x8000

    li r10, UNUNSED
    stb r10, FLAG(r12)


    beq has_blooper
    b else

has_blooper:
    lis r12, 0x8000
    lbz r11, COIN_AMOUNT(r12) #load coin amount
    cmpwi r11, 10
    
    li r10, UNUNSED
    stb r10, FLAG(r12)
    
    blt canAdd
    b else
    #set FLAG

canAdd:
    lis r12, 0x8000

    lbz r10, FLAG(r12)
    cmpwi r10, 0

    #set it
    beq zero
    b one

zero:
    lis r12, 0x8000

    li r10, 1
    stb r10, FLAG(r12)
    
    b coinAmount

one:
    lis r12, 0x8000

    li r10, 0
    stb r10, FLAG(r12)
    
    b coinAmount

coinAmount:
    lis r12, 0x8000
    lbz r10, FLAG(r12)

    cmpwi r10, 1
    beq increment
    b else


increment:
    addi r11, r11, 1
    stb r11, COIN_AMOUNT(r12)

    b else

else:

    #modify speed
    
    
    #load defualt speed into f2
    


    lbz r10, DEFAULT_SPEED(r12)
    cmpwi r10, 0
    bne set
    b not
set:
    #load value of 0.01 into r12
    lis r12, 0x3c23
    ori r12, r12, 0xd70a
    
    lis r11, 0x8000
    
    stw r12, ONE_PERCENT(r11)
    
    #load 0.01 into f3
    lfs f3, ONE_PERCENT(r11)
    
    #multiply to get 1% of default speed
    #store the result in f3
    lfs f2, DEFAULT_SPEED(r12)
    fmuls f3, f2, f3

    lis r12, 0x8000
    stfs f3, ONE_PERCENT_OF_DEFAULT_SPEED(r12)

    #witchcraft conversion
    #result is in f3


    lis r12, 0x4330
    stw r12, -0x8 (r10)
    lis r12, 0x8000
    stw r12, -0x4 (r10)
    lfd f2, -0x8 (r10) # load magic double into f2
    xoris r11, r11, 0x8000 # flip sign bit
    stw r11, -0x4 (r10) # store lower half (upper half already stored)
    lfd f3, -0x8 (r10)
    fsub f3, f3, f2 # complete conversion

    lis r12, 0x8000
    stfs f3, 0x1cc(r12)
    #multiply 1% of default speed (f10) by coin amount (f3) to get the speed increase
    #store result in f2

    #load 1% of deFafult speed into f2
    lis r12, 0x8000
    lfs f2, ONE_PERCENT_OF_DEFAULT_SPEED(r12) 


    fmuls f2, f3, f2

    #load default speed into f3
    lfs f3, DEFAULT_SPEED(r12)
    stfs f3, MODIFIED_SPEED(r12) 

    #add default speed (f3) and speed increase (f2)
    #store result in f3

    fadds f3, f3, f2

    #store the value of f3 at 0x8000 01d4 (modified speed)

    lis r12, 0x8000

not:
blr