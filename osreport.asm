.set region, 'E'
.set codePosition, 0x800014B0 # change this to the address you want to write this function to

.if     (region == 'E' || region == 'e') # RMCE
        .set drawDebugBar, 0x80009640
        .set nw4r_db_DirectPrint_ChangeXfb, 0x80021D90
        .set nw4r_db_DirectPrint_Printf, 0x80021DF0
        .set nw4r_db_DirectPrint_StoreCache, 0x80021DD0
        .set VIGetNextFrameBuffer, 0x801BAA84
        .set r28thing, 0x802A307C
.elseif (region == 'P' || region == 'p') # RMCP
        .set drawDebugBar, 0x80009680
        .set nw4r_db_DirectPrint_ChangeXfb, 0x80021e30
        .set nw4r_db_DirectPrint_Printf, 0x80021E90
        .set nw4r_db_DirectPrint_StoreCache, 0x80021E70
        .set VIGetNextFrameBuffer, 0x801BAB24
        .set r28thing, 0x802A73FC
.elseif (region == 'J' || region == 'j') # RMCJ
        .set drawDebugBar, 0x800095DC
        .set nw4r_db_DirectPrint_ChangeXfb, 0x80021D50
        .set nw4r_db_DirectPrint_Printf, 0x80021DB0
        .set nw4r_db_DirectPrint_StoreCache, 0x80021D90
        .set VIGetNextFrameBuffer, 0x801BAA44
        .set r28thing, 0x802A6D7C
.elseif (region == 'K' || region == 'k') # RMCK
        .set drawDebugBar, 0x80009788
        .set nw4r_db_DirectPrint_ChangeXfb, 0x80021E90
        .set nw4r_db_DirectPrint_Printf, 0x80021EF0
        .set nw4r_db_DirectPrint_StoreCache, 0x80021ED0
        .set VIGetNextFrameBuffer, 0x801BAE80
        .set r28thing, 0x802953FC
.else # Invalid Region
        .abort
.endif

.macro push_stack size, registers
      stwu r1, \size(r1)
      stmw \registers, 8(r1)
.endm

.macro pop_stack registers, size
      lmw \registers, 8(r1)
      addi r1, r1, \size
.endm

# 04 Write
#b 0x800014B0 - drawDebugBar # branch to the 06 code

# 06 Write
# Function Prologue...
push_stack -128, r3

lis r5, r28thing@ha
lwz r5, r28thing@l(r5)
lhz r4, 0x4(r5) # width
lhz r5, 0x8(r5) # height

bl -((codePosition + 0x18) - VIGetNextFrameBuffer)
bl -((codePosition + 0x1C) - nw4r_db_DirectPrint_ChangeXfb)

li r3, 0   # X coordinate of text start
li r4, 220 # Y coordinate of text start
li r5, 1   # Wrap text

lis r12, 0x8000
lwz r6, 0x3b0(r12)
bl -((codePosition + 0x3C) - nw4r_db_DirectPrint_Printf)
bl -((codePosition + 0x40) - nw4r_db_DirectPrint_StoreCache)

# Function Epilogue...
pop_stack r3, 128

lwz r12, 0(r3) # original instruction
b -((codePosition + 0x50) - (drawDebugBar+4)) # branch back 