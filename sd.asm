Source:
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 2.0.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License 2.0 for more details.

#START ASSEMBLY

#Macros
.set ios_open, 0x801938f8
.set ios_ioctl, 0x80194290
.set ios_ioctlv, 0x801945e0
.set ios_close, 0x80193ad8

.macro call_ios_open
mtctr r24
bctrl
.endm

.macro call_ios_ioctl
mtctr r25
bctrl
.endm

.macro call_ios_ioctlv
mtctr r26
bctrl
.endm

.macro call_ios_close
mtctr r27
bctrl
.endm

.macro prologue
stwu sp, -0x0300 (sp)
mflr r0
stw r0, 0x0304 (sp)
stmw r14, 0x02B8 (sp)
.endm

.macro epilogue
lmw r14, 0x02B8 (sp)
lwz r0, 0x0304 (sp)
mtlr r0
addi sp, sp, 0x0300
blr
.endm

#Register Notes
#r31 = Second Output Buffer
#r30 = Vector Root aka Vector Table
#r29 = Output Buffer
#r28 = Input Buffer
#r27 = IOS_Close
#r26 = IOS_Ioctlv
#r25 = IOS_Ioctl
#r24 = IOS_Open
#r23 = r3 arg
#r22 = r4 arg
#r21 = r5 arg
#r20 = LUT Pointer
#r19 = SD fd
#r18 = RCA (relative card address)
#r17 = 0x200 (Block Length)

#Put function at 0x800001B0; adjust this accordingly to your needs
lis r11, 0x8000
addi r12, r15, 0x10 #r15 from codehandler points to start of this C0 code
stw r12, 0x1B0 (r11)
blr

#Prologue
prologue

#Place Args in GVRs
mr r23, r3
mr r22, r4
mr r21, r5

#Set LUT (Lookup Table)
bl table
.long ios_open
.long ios_ioctl
.long ios_ioctlv
.long ios_close
.string "/dev/sdio/slot0"
.align 2
table:
mflr r20

#Load all IOS Function Call Pointers from LUT into r24 thru r27, r28 and up will be used after this
lmw r24, 0 (r20)

#Adjust Stack so pointers/buffers can be 32 byte aligned
mr r12, sp
andi. r0, sp, 0x0010
bne- setup_pointers

addi r12, r12, 0x0010

#Setup all Pointers/Buffers
setup_pointers:
addi r28, r12, 0x8
addi r29, r12, 0x48
addi r30, r12, 0x68
addi r31, r12, 0xA8

#Open SD card
addi r3, r20, 0x10 #Points to sd dev path
li r4, 0
call_ios_open
cmpwi r3, 0
blt- end_function
mr r19, r3 #Backup fd

#Reset SD card and get new RCA; r3 already set
reset_sd:
li r4, 4
li r5, 0
li r6, 0
mr r7, r29
li r8, 4
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Get SD Status Not Needed
#If done SD status returns one word
#Bit 15 = SDIO Int Pending (1 = Not Busy, 0 = Busy)
#Bit 30 = SDIO Interrupt (set to 1 if no SD card, bad SD card, or some other error)
#Bit 31 = Card Present (set to 1 if Bit 30 is 0 and a valid SD card is present)
#All other bits unused

#Dolphin Fix
#Sometimes Dolphin won't return an rca on certain games after calling Reset SD, don't know why. However when it does, it always returns an rca value of 0x0001. So let's fix it.
#Check if on Dolphin, it always uses a value of 0x00000000 on GPIO list for HW_GPIOB_OUT
lis r3, 0xCD80
lwz r0, 0x00C0 (r3)
cmpwi r0, 0
lis r18, 0x0001
beq- select_sd

#RCA is returned in upper 16 bits, lower 16 bits is 'stuff bits' which is always 0x0000
#WiiBrew says to and the status with FFFF0000, but stuff bits ALWAYS returns 0x0000
#W/e do it just in case. Save status in r18; ill double check this later in Brawl
lwz r18, 0 (r29)
andis. r18, r18, 0xFFFF

#Setup Args for Selecting the SD card
select_sd:
bl pre_ios_ioctl_send_cmd

#Setup Input Buffer Contents (7,3,2,rca&0xFFFF0000,0,0,0)
li r0, 7
stw r0, 0 (r5)
li r0, 3
stw r0, 0x4 (r5)
li r0, 2
stw r0, 0x8 (r5)
stw r18, 0xC (r5) #RCA

#0x10 thru 0x23 = null

#Set 0x10 thru 0x23 words as null so it stays null through rest of SD calls
li r0, 0
stw r0, 0x10 (r5)
stw r0, 0x14 (r5)
stw r0, 0x18 (r5)
stw r0, 0x1C (r5)
stw r0, 0x20 (r5)

#Select the SD card
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Setup Args for Setting the Block Length
bl pre_ios_ioctl_send_cmd

#Setup Input Buffer Contents (0x10,3,1,0x200,0,0,0)
li r0, 0x10
stw r0, 0 (r5)
#0x4 word already at 3
li r0, 1
stw r0, 0x8 (r5)
li r17, 0x200 #The Block Length; place in r17, will be used multiple times later
stw r17, 0xC (r5)

#0x10 thru 0x23 = null

#Set Block Length to 0x200
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Setup Args for Setting the Bus Width to 4 (Part 1/4)
bl pre_ios_ioctl_send_cmd

#Setup Input Buffer Contents (0x37,3,1,rca&0xFFFF0000,0,0,0)
li r0, 0x37
stw r0, 0 (r5)
#0x4 and 0x8 words already set
stw r18, 0xC (r5)

#0x10 thru 0x23 = null

#Set Bus Width to 4 (Part 1/4)
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Setup Args for Setting the Bus Width to 4 (Part 2/4)
bl pre_ios_ioctl_send_cmd

#Setup Input Buffer Contents (6,3,1,2,0,0,0)
li r0, 6
stw r0, 0 (r5)
#0x4 and 0x8 words already set
li r0, 2
stw r0, 0xC (r5)

#0x10 thru 0x23 = null

#Set Bus Width to 4 (Part 2/4)
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Setup Args for Setting the Bus Width to 4 (Part 3/4)
#Setup SD_HC_READ8
mr r3, r19
li r4, 2
mr r5, r28
li r6, 0x18
mr r7, r29
li r8, 4

#Setup Input Buffer Contents (0x28,0,0,1,0,0)
li r0, 0x28
stw r0, 0 (r5)
li r0, 0
stw r0, 0x4 (r5)
stw r0, 0x8 (r5)
li r0, 1
stw r0, 0xC (r5)
#0x10 and 0x14 words already set to 0 from earlier

#Call SD_HC_READ8 (Bus width 3/4)
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Setup Args for Setting Bus Width to 4 (Part 4/4)
#Setup SD_HC_WRITE_8
mr r3, r19
li r4, 1
mr r5, r28
li r6, 0x18
li r7, 0
li r8, 0

#Take Output Buffer from SD_HC_READ8, logical and it with 2, then logical or it with 2
lwz r0, 0 (r29)
andi. r0, r0, 2
ori r0, r0, 2 #r0 = reg

#Setup Input Buffer Contents (0x28,0,0,1,reg,0)
#0x0, 0x4, 0x8, 0xC, and 0x14 words already set from last time
stw r0, 0x10 (r5)

#Call SD_HC_WRITE8 (Bus width 4/4)
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Setup Args for Clocking the SD
mr r3, r19
li r4, 6
mr r5, r28
li r6, 4
li r7, 0
li r8, 0

#Setup Input Buffer Contents
li r0, 1
stw r0, 0 (r5)

#Clock the SD
call_ios_ioctl
cmpwi r3, 0
bne- end_function

#Dump the first 0x200 bytes of the SD card physically

#Setup Args for SD Read Multi Block
bl pre_ios_ioctlv

#Setup Vector Root Index aka Vector Table (r7)
stw r28, 0 (r7) #First Vector Input Buffer
li r0, 0x24 #Size of First Vector Input Buffer
stw r0, 0x4 (r7)
stw r31, 0x8 (r7) #Second Vector Input Buffer (this is actually the output buffer where the physical SD contents are dumped, weird that's used as an Input Buffer in the Vector table, but this is how Brawl and Zelda Twilight do it, so it's correct).
stw r17, 0xC (r7) #0x200 for dumping 0x200 bytes
stw r29, 0x10 (r7) #Output/Reply Buffer for the Vector, fyi, not really important but has to be set
li r0, 0x10 #Size of Output/Reply Buffer
stw r0, 0x14 (r7)

#Setup Vector First Input Pointer Contents (r28); (0x12,3,1,physicaloffset,1,0x200,&buffer,1,0)
li r0, 0x12 #CMD for READ; fyi use 0x19 for WRITE
stw r0, 0 (r28)
li r0, 3
stw r0, 0x4 (r28)
li r8, 1 #Place in r8, will be used again
stw r8, 0x8 (r28)
li r0, 0 #Address offset of SD card, 0 for very start of SD
stw r0, 0xC (r28)
stw r8, 0x10 (r28)
stw r17, 0x14 (r28) #0x200 Block width
stw r31, 0x18 (r28) #Second Vector Input Pointer aka place where SD will be dumped
stw r8, 0x1C (r28)

#0x20 thru 0x23 = null

#Set 0x20 as null so it stays null through future calls
#r0 already set to null from earlier, setting address offset to 0
stw r0, 0x20 (r28)

#DUMP THE SD!
call_ios_ioctlv
cmpwi r3, 0
bne- end_function

#########################

#r31 = MBR
#r28 = Input Buffer (1st Input Pointer of Vector)
#r17 = 0x200

#Master Boot Record dumped, figure out where Partition is at; put in r20, will be used later
li r3, 0x1C6 #This is correct due to nearby MBR values being 10 bit strings
lwbrx r20, r31, r3
mullw r20, r20, r17 #times it by 0x200

#Setup Args for SD READ MULTI BLOCK
bl pre_ios_ioctlv

#Vector table (r7) has everything set from last time, just set diff offset to dump
stw r20, 0xC (r28)

#DUMP THE SD Partition (first 0x200 bytes of it aka the Boot/Reserved Sector)
call_ios_ioctlv
cmpwi r3, 0
bne- end_function

#Figure out all BPB's and other important values/pointers from the Boot Sector of the SD
#r31 = Where Boot Sector is at
#r25 = Root/Data Start Sector
#r20 = Partition Physical Offset
#r16 = BPB_BytesPerSector
#r15 = BPB_SecPerClus
#r14 = BPB_RsvdSecCnt
#r12 = BPB_NumFATs
#r11 = BPB_TotSec32
#r10 = BPB_FATSz32
#r9 = FATsz

#Get BPB_BytesPerSector
li r3, 0xB
lhbrx r16, r31, r3

#Check if BPB_BytesPerSector is 0x200. If not, throw error.
cmpwi r16, 0x200
li r3, -31
bne- end_function

#Get BPB_SecPerClus
lbz r15, 0xD (r31)

#Get BPB_RsvdSecCnt
li r3, 0xE
lhbrx r14, r31, r3

#Get BPB_NumFATs
lbz r12, 0x10 (r31)

#Get BPB_TotSec32
li r3, 0x20
lwbrx r11, r31, r3

#Get BPB_FATSz32
li r3, 0x24
lwbrx r10, r31, r3

#Calculate FATsz (aka FAT sectors)
#BPB_FATSz32 x BPB_NumFATs
mullw r9, r10, r12

#Calculate Root/Data Start Sector (always same on FAT32, so we just need to calculate Root Start Sector)
#BPB_RsvdSecCnt + FATsz aka FAT Sectors
add r25, r14, r9

#Check if partition is FAT32
#Calculate total Clusters first
#(BPB_TotalSec32 - Data aka Root Start Sector) / BPB_SecPerClus
sub r3, r11, r25
divw r0, r3, r15

#FAT32 must have at least 65525 clusters (0xFFF5)
cmplwi r0, 0xFFF5
li r3, -32
blt- end_function

#r31 = Where Boot Sector is at (Offset 0x0)
#r25 = Root/Data Start Sector
#r20 = Partition Physical Offset
#r17 = 0x200 then Root/Data Start Physical Offset
#r16 = BPB_BytesPerSector
#r15 = BPB_SecPerClus
#r14 = BPB_RsvdSecCnt

#Calculate FAT physical offset
#[BPB_BytesPerSector * BPB_RsvdSecCnt] + Partition Physical Offset
mullw r24, r16, r14
add r24, r24, r20

#Calculate Root/Data offset, will need to use it later
#[(BPB_BytesPerSector * Root/Data Start Sector)] + Partition Physical Offset
mullw r17, r16, r25
add r17, r17, r20

###

#Big azz loop to attempt to find file name in entire root/data sector

root_data_sector_loop:
#Got the Root/Data offset, now Dump it, replacing the Boot sector dump
bl pre_ios_ioctlv

#Change Address Offset of SD (root/data physical offset) in Vector First Input, everything else already set
stw r17, 0xC (r28)

#0x20 thru 0x23 = null ofc

#Dump SD contents (Root/data Start Sector)
call_ios_ioctlv
cmpwi r3, 0
bne- end_function

#########################

#We are now at Root/Data start Sector area (starts at very beginning of Root/Data sector)

#r31 = Data/Root Location in Memory
#r25 = Root/Data Start Sector
#r24 = Fat Physical Offset
#r20 = Partition Physical Offset
#r17 = Current Root/Data Sector Physical Address dumped (first execute of loop at start of Root/Data Physical Offset)
#r16 = BPB_BytesPerSector
#r15 = BPB_SecPerClus

#Setup Load Byte Item Loop CTR and r8

li r0, 0x20
mtctr r0 #0x200 / 0x10 = 32 rows to check per dump
addi r8, r31, -0x10

#Check if end of Root/Data has been reached
load_byte_item:
lbzu r0, 0x10 (r8)
cmpwi r0, 0
li r3, -33 #Error for file not found
beq- end_function

#Check for 0x0F byte at 0xB offset (ATTR_LONG_FILE_NAME byte)
lbz r0, 0xB (r8)
cmpwi r0, 0xF
bne- decrement_loop

#LFN byte found, check if file has extended name; if so, go to next item
lbz r0, 0 (r8)
cmpwi r0, 0x41 #0x41 indiciates valid item with non extended name
bne- decrement_loop

#Valid Item found, parse the name
addi r9, r8, -1
addi r10, sp, -0x21
li r7, 5

name_parse_first_part:
lbzu r0, 0x2 (r9)
stbu r0, 0x1 (r10)
subic. r7, r7, 1
bne+ name_parse_first_part

addi r9, r8, 0xC
li r7, 6

name_parse_second_part:
lbzu r0, 0x2 (r9)
stbu r0, 0x1 (r10)
subic. r7, r7, 1
bne+ name_parse_second_part

lbz r0, 0x1C (r8)
stbu r0, 0x1 (r10)

lbz r0, 0x1E (r8)
stbu r0, 0x1 (r10)

#Get Length of User's File Name
addi r9, r23, -1
li r7, 0

file_name_length:
addi r7, r7, 1
lbzu r0, 0x1 (r9)
cmpwi r0, 0
bne+ file_name_length

cmplwi r7, 13
li r3, -35
bgt- end_function

#Compare User's Name to Current Parsed name
addi r9, r23, -1
addi r10, sp, -0x21

name_compare_loop:
lbzu r0, 0x1 (r9)
lbzu r3, 0x1 (r10)
cmpw r0, r3
bne- decrement_loop

subic. r7, r7, 1
bne+ name_compare_loop

#Name match, file found
b file_found

decrement_loop:
bdnz+ load_byte_item

#Dump next 0x200 of Root/Data Sector to keep trying to find file
addi r17, r17, 0x200
b root_data_sector_loop

#File found, Compare the size to the user's byte arg for writing. If the arg is greater than the size, throw an error code.
file_found:
li r4, 0x3C
lwbrx r0, r8, r4
cmplw r21, r0
li r3, -36
bgt- end_function

#Get the Initial Cluster Number of the file
li r5, 0x34
lhbrx r3, r8, r5
li r5, 0x3A
lhbrx r4, r8, r5
slwi r3, r3, 16
or r17, r3, r4 #Cluster number now in r17; needs to be saved over next function call

########################

#Mega Write Loop; Editing the actual File

#Setup r22 intially (User's arg pointing to start of buffer contents to be written)
addi r22, r22, -1

#Use initial cluster number to set physical offset of start of file on SD
bl cluster_to_physical_offset

mega_file_write_loop:
#Update physical offset on Vector First Input
stw r14, 0xC (r28)

#r31 = Start of Files Current Contents
#r24 = Fat physical offset
#r22 = Contents to be Written
#r21 = User's bytes to write
#r20 = Parition Physical Offset
#r18 = File Physical Offset
#r17 = First Cluster Number of File
#r16 = BPB_BytesPerSector
#r15 = BPB_SecPerClus
#r14 = Physical Offset for CMD_WRITE_MULTI_BLOCK of Vector First Input

#Null out the 0x200 buffer beforehand
li r0, 0x80 #0x200 / 4 = 0x80
mtctr r0
addi r3, r31, -4
li r0, 0

null_loop:
stwu r0, 0x4 (r3)
bdnz+ null_loop

#Setup Loading Address for Edit Loop
addi r3, r31, -1

#Set Max loop for this stage
li r0, 0x200 #Preset CTR to 0x200 cause 0x200 bytes can only be sent at a time in the write buffer
mtctr r0

cmplw r21, r0 #Check if main loop is less than 0x200, if so, use that instead
bgt- edit_loop

mtctr r21 #Change CTR value to r21 since bytes left to written is under 0x200

edit_loop:
lbzu r0, 0x1 (r22)
stbu r0, 0x1 (r3)
bdnz+ edit_loop

#File Contents in Memory edited, setup ios_ioctlv
bl pre_ios_ioctlv

#Change CMD back to WRITE MULTI BLOCK in Vector Frist input, offset from last is still there (file offset)
li r0, 0x19
stw r0, 0 (r28)

#Write the SD with new file contents!
call_ios_ioctlv
cmpwi r3, 0
bne- end_function

#Now update main loop, if r21 ends up being 0 or lower, the writing has ended, close SD
subic. r21, r21, 0x200 #Number result can be negative, signed comparison is appropriate for the bgt instruction
ble- close_sd

#Writing hasn't ended, check if next 0x200 bytes of file spans across a different cluster.
#Equation to find FAT entry in Cluster Chain
#[(N * 4) + Fat Physical Offset]
#N = Cluster Number aka r17
slwi r3, r17, 2 #Shift Left by 2 = Multiply by 4
add r3, r3, r24 #Finalized physical address where cluster word chain is at

#The cluser chain word could be located at an address not aligned by 0x200, fix this issue
clrrwi r4, r3, 9
sub r23, r3, r4 #Subtract aligned address value from possible misaligned address value; use 23, value needs to stay intact
stw r4, 0xC (r28) #Update vector first input contents

#Switch to READ, dump FAT contents, check cluster number
bl pre_ios_ioctlv

#Switch to CMD_READ_MULTI_BLOCK
li r0, 0x12
stw r0, 0 (r28)

#Dump contents (cluster chain will be first word shown)
call_ios_ioctlv
cmpwi r3, 0
bne- end_function

#r31 = Start of Files Current Contents
#r25 = Root/Data Start Sector
#r24 = Fat physical offset
#r23 = Margin
#r22 = Contents to be Written
#r21 = User's bytes to write
#r20 = Parition Physical Offset
#r18 = File Physical Offset
#r17 = Cluster Number
#r16 = BPB_BytesPerSector
#r15 = BPB_SecPerClus

#Load Current Cluster word, replace old cluster number that's in r17
lwbrx r17, r23, r31 #r23 contains the offset amount to load by from previous instructions to align address by 0x200

#Check if Bad Cluster
lis r0, 0x0FFF
ori r0, r0, 0xFFF7
cmplw r17, r0 #logical compare because of bltl- branch that occurs a little bit later
li r3, -34
beq- end_function

#Check for Final Cluster
#If not calculate new physical offset from new cluster number
#If final cluster found, then simply increment current physical offset by 0x200
#Fyi, new cluster is anything less than 0x0FFFFFF7 logically
addi r14, r14, 0x200
bltl- cluster_to_physical_offset #r14 will be overwritten with entirely new physical offset if this branch gets taken
b mega_file_write_loop #Continue with the loop, first instruction of loop updates the physical offset for vector first input

#Close SD card
close_sd:
mr r3, r19
call_ios_close

#No need for final r3 check

#Epilogue
end_function:
epilogue

#Subroutine SD_Send_CMD (when Ioctl has r4 arg of 7)
pre_ios_ioctl_send_cmd:
mr r3, r19
li r4, 7
mr r5, r28
li r6, 0x24
mr r7, r29
li r8, 0x10
blr

#Subroutine for Setting up Args for Ios_Ioctlv
pre_ios_ioctlv:
mr r3, r19
li r4, 7
li r5, 2
li r6, 1
mr r7, r30
blr

#Subroutine for using Cluster Number to Get Physical Offset
#{[(N - 2) * BPB_SecPerClus) + FirstDataSector] * BPB_BytesPerSector} + PartitionPhysicalOffset
#N = Cluster Number aka r17
cluster_to_physical_offset:
subi r3, r17, 2
mullw r3, r3, r15
add r3, r3, r25
mullw r3, r3, r16
add r14, r20, r3 #Place in r14 we need this value to stay intact
blr

#END ASSEMBLY