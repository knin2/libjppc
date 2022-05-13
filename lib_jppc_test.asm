import libjppc/lib_jppc.asm
import libjppc/libmenu.asm
head:
	libmenu_init
	bl txt
	.string "text"
        .balign 4

	txt:
	mflr r11
	set_message_id 0x6E 0x232a #r11 = string pointer
blr

