runtime libjppc/libmenu_selection_runtime.gcode
runtime libjppc/libmenu_current_screen.gcode
runtime libjppc/libmenu_layout_ui_control.gcode
#LIBMENU - CODED BY JAWA 6/5/2022
INFO:
	#using 14B0 - 16B0
	#15B0 - TEMPORARY REGISTER STORAGE
.set REGION_OFFSET, 0x14b0
.set FUNC_FAILURE, 0x33f5

.set REGION_USA, 1
.macro libmenu_init
	.set input_data_PAL, 0x809bd70c
	.set input_data_USA, 0x809b8f4c
	.set input_data_JAP, 0x809bc76c
	.set input_data_KOR, 0x809abd4c
	lis r12, 0x8000
	ori r12, r12, REGION_OFFSET
	lis r11, input_data_PAL@h
	ori r11, r11, input_data_PAL@l
	stwu r11, 0(r12)
	lis r11, input_data_USA@h
	ori r11, r11, input_data_USA@l
	stwu r11, 4(r12)
	lis r11, input_data_JAP@h
	ori r11, r11, input_data_JAP@l
	stwu r11, 4(r12)
	lis r11, input_data_KOR@h
	ori r11, r11, input_data_KOR@l
	stw r11, 4(r12)
.endm

INPUT:
	.macro get_input_data region
		lis r12, 0x8000
		ori r12, r12, REGION_OFFSET
		li r3, \region
		cmpwi r3, 4
		bge F
		mulli r3, r3, 4
		add r12, r12, r3
		lwz r3, 0(r12)
		lwz r3, 0(r3)
		b ret_zero
		F:
			li r3, FUNC_FAILURE
		ret_zero:
			nop
	.endm

	.macro get_input_state
		lwz r3, 8(r3)
		addi r3, r3, 8
	.endm
	.macro get_a_button_pressed
		get_input_state
		lhz r3, 0(r3)
		li r4, 1
		and r3, r3, r4
		cmpwi r3, 1
		bne return_false
		b return_true
		return_false:
			li r3, 0
			b return_
		return_true:
			li r3, 1
		return_:
			nop
	.endm
MENU:
	#USES 0x14C0 - 14C1
	.macro get_cup_selection_element
		lis r3, 0x8000
		lbz r3, 0x14C0(r3)
	.endm
	.macro get_cup_element_clicked
		get_cup_selection_element #r3 = element.id
		cmpw r3, r4
		bne return_false_

		get_input_data REGION_USA #r3 = input_data
		get_a_button_pressed #r3 = a_button_pressed

		cmpwi r3, 1
		bne return_false_

		b return_true_
		return_false_:
			li r3, 0
			b return
		return_true_:
			li r3, 1
		return:
			nop
	.endm
	#USES 0x14C1 - 14C2
	.macro get_current_screen
		lis r3, 0x8000
		lbz r3, 0x14C1(r3)
	.endm
	.macro get_layout_ui_control
		lis r3, 0x8000
		lwz r3, 0x14C2(r3)
	.endm
	.macro set_message_id screen id
		.set LayoutUIControl_setMessageAll, 0x8060c89c
		get_current_screen

		cmpwi r3, \screen
		bne retn
		get_layout_ui_control

		mr r4, r11
		
		li r5, \id
		li r6, 0

		call LayoutUIControl_setMessageAll
		retn:
			nop
	.endm