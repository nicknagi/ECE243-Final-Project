# r10 - JTAG keyboard
# r11 - Timer
# r8 - Lego controller
# r12 - PS 2 keyboard
# r9 - HEX Display (HEX 0 -> 3)
# r18 -> Score Count robot 1
# r19 -> Score count robot 2

# r13, r14, r16, 17 - temp

.global	_start

	.equ PS_2_KEYBOARD, 0xFF200100

	.equ ADDR_JP1,0xFF200070
	.equ MOTORS_STOP ,   0b11111101010111111111111111111111

	.equ LOAD_SENSOR0_THRESHOLD ,   0b11111100001111111111101111111111
	.equ LOAD_SENSOR1_THRESHOLD ,   0b11111100001111111110111111111111

	#Values for HEX Display

	.equ HEX_ZERO, 0b0111111
	.equ HEX_ONE, 0b0000110
	.equ HEX_TWO, 0b1011011
	.equ HEX_THREE, 0b1001111
	.equ HEX_FOUR, 0b1100110
	.equ HEX_FIVE, 0b1101101
	.equ HEX_SIX, 0b1111101
	.equ HEX_SEVEN, 0b0000111
	.equ HEX_EIGHT, 0b1111111
	.equ HEX_NINE, 0b1101111

	.equ JTAG, 0xFF201000

	.equ HEX, 0xFF200020

	.equ TIMER, 0xFF202000
	.equ  TIMER0_STATUS,    0
	.equ  TIMER0_CONTROL,   4
	.equ  TIMER0_PERIODL,   8
	.equ  TIMER0_PERIODH,   12
	.equ  TIMER0_SNAPL,     16
	.equ  TIMER0_SNAPH,     20
	.equ  TICKSPERSEC,      5000000

	.equ RED_LEDS, 0xFF200000 	   # (From DESL website > NIOS II > devices)


#JTAG ascii table
	.equ left_back_1, 0x31
	.equ back_2, 0x32
	.equ right_back_3, 0x33
	.equ left_4, 0x34
	.equ stop_5, 0x35
	.equ right_6, 0x36
	.equ left_forward_7, 0x37
	.equ forward_8, 0x38
	.equ right_forward_9, 0x39

#PS2 values table
	.equ l_b_1, 0x69
	.equ b_2, 0x72
	.equ r_b_3, 0x7A
	.equ l_4, 0x6B
	.equ s_5, 0x73
	.equ r_6, 0x74
	.equ l_f_7, 0x6C
	.equ f_8, 0x75
	.equ r_f_9, 0x7D


###################################### INTERRUPT HANDLER ##################################
	.section .exceptions, "ax"
myISR:

	#allocate space on stack
	subi sp,sp,20

	#Store registers modified
	stw r13,0(sp)
	stw r14,4(sp)
	stw r15,8(sp)
	stw r23,12(sp)
	stw ea,16(sp)

	rdctl r14, ipending

	#DETERMINE WHAT CASUED THE INTERRUPT

	#JTAG Interrupt
	add r13, r14, r0
	andi r13 ,r13, 0b0100000000
	movi r15, 0b0100000000
	beq r13,r15,JTAG_INTERRUPT

	#Timer Interrupt
	add r13, r14, r0
	andi r13 ,r13, 0x00000001
	movi r15, 0x00000001
	beq r13,r15,TIMER_INTERRUPT

	#Sensor Interrupt
	add r13, r14, r0
	andi r13 ,r13, 0b01000000000000
	movi r15, 0b01000000000000
	beq r13,r15,SENSOR_INTERRUPT

	#PS2 INTERRUPT
	add r13, r14, r0
	andi r13 ,r13, 0b0010000000
	movi r15, 0b0010000000
	beq r13,r15, PS2_INTERRUPT

PS2_INTERRUPT:

ldwio r23, 0(r12)
andi r23, r23, 0b011111111

movia r13, b_2
beq r23, r13, BACK_robot2

movia r13, f_8
beq r23, r13, FORWARD_robot2

movia r13, l_f_7
beq r23, r13, FORWARD_LEFT_robot2

movia r13, r_f_9
beq r23, r13, FORWARD_RIGHT_robot2

movia r13, l_4
beq r23, r13, LEFT_robot2

movia r13, r_6
beq r23, r13, RIGHT_robot2

movia r13, l_b_1
beq r23, r13, BACKWARDS_LEFT_robot2

movia r13, r_b_3
beq r23, r13, BACKWARDS_RIGHT_robot2

movia r13, s_5
beq r23, r13, STOP_robot2

#stwio r23, 0(r10)
br RETURN

	BACK_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run backwards ie bits 7 to 4 are 0000
		movia r14, 0xffffff0f
		and r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run forward ie bits 7 to 4 are 1010
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b010100000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_LEFT_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run forward left ie bits 7 to 4 are 0110
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b01100000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_RIGHT_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run forward right ie bits 7 to 4 are 1001
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b010010000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	LEFT_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run left ie bits 7 to 4 are 0010
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b0100000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	RIGHT_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run right ie bits 7 to 4 are 1000
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b010000000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	BACKWARDS_LEFT_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run backwards left ie bits 7 to 4 are 0100
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b01000000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	BACKWARDS_RIGHT_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run backwards right ie bits 7 to 4 are 0001
		movia r14, 0xffffff0f
		and r13, r13, r14
		movia r14, 0b010000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	STOP_robot2:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 stop ie bits 7 to 4 are 1111
		movia r14, 0b011110000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

#ROBOT IS OUT OF BOUNDS
SENSOR_INTERRUPT:
#INCREMENT COUNTER AND DISPLAY ON HEX
		ldwio r13, 0(r8)
		srli r13, r13, 27
		andi r13,r13,0x1

		#If sensor 0 was the reason then increment counter for robot 2
		beq r13,r0, INCREMENT_ROBOT_2_COUNTER

		ldwio r13, 0(r8)
		srli r13, r13, 28
		andi r13,r13,0x1

		#If sensor 1 was the reason then increment counter for robot 1
		beq r13,r0, INCREMENT_ROBOT_1_COUNTER

		#Acknowledge the interrupt
		movia r13, 0xFFFFFFFF
		stwio r13, 12(r8)

		br RETURN

INCREMENT_ROBOT_2_COUNTER:
	addi r19,r19,1
	br CHECK_ENDGAME

INCREMENT_ROBOT_1_COUNTER:
	addi r18,r18,1


CHECK_ENDGAME:
	#Stop the motors
	movia r13, MOTORS_STOP
	stwio r13, 0(r8)

	#Update score for robot 2
	mov r4,r19
	movi r5,1
	call display_hex_number

	#Update score for robot 1
	mov r4,r18
	movi r5,0
	call display_hex_number

	#Acknowledge the interrupt
	movia r13, 0xFFFFFFFF
	stwio r13, 12(r8)

	br RETURN


JTAG_INTERRUPT:
#Read some information now
movia r10, JTAG
ldwio r23, 0(r10)

#Get the ls 7 bits (data)
andi r23, r23, 0b011111111

movia r13, back_2
beq r23, r13, BACK_robot1

movia r13, forward_8
beq r23, r13, FORWARD_robot1

movia r13, left_forward_7
beq r23, r13, FORWARD_LEFT_robot1

movia r13, right_forward_9
beq r23, r13, FORWARD_RIGHT_robot1

movia r13, left_4
beq r23, r13, LEFT_robot1

movia r13, right_6
beq r23, r13, RIGHT_robot1

movia r13, left_back_1
beq r23, r13, BACKWARDS_LEFT_robot1

movia r13, right_back_3
beq r23, r13, BACKWARDS_RIGHT_robot1

movia r13, stop_5
beq r23, r13, STOP_robot1

#stwio r23, 0(r10)
br RETURN

	BACK_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run backwards ie last 4 bits 0000
		movia r14, 0xfffffff0
		and r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run forward ie last 4 bits 1010
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b01010
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_LEFT_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run forward left ie last 4 bits 0110
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b0110
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_RIGHT_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run forward right ie last 4 bits 1001
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b01001
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	LEFT_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run left ie last 4 bits 0010
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b010
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	RIGHT_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run right ie last 4 bits 1000
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b01000
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	BACKWARDS_LEFT_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run backwards left ie last 4 bits 0100
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b0100
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	BACKWARDS_RIGHT_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 run backwards right ie last 4 bits 0001
		movia r14, 0xfffffff0
		and r13, r13, r14
		movia r14, 0b01
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

	STOP_robot1:
		ldwio r13,	0(r8) #load current values of lego controller

		#modify values so motors of robot 1 stop ie last 4 bits 1111
		movia r14, 0b01111
		or r13, r13, r14

		stwio	r13,	0(r8) #write the value
		br RETURN

TIMER_INTERRUPT:

RETURN:

#restore registers modified
	ldw r13,0(sp)
	ldw r14,4(sp)
	ldw r15,8(sp)
	ldw r23,12(sp)
	ldw ea,16(sp)

	#deallocate space on stack
	addi sp,sp,20

subi ea,ea,4
eret

################################## MAIN CODE ###############################

_start:

	#Initialize stack pointer
	movia sp, 0x03FFFFFC

	#set up JTAG keyboard and timer
	movia r10, JTAG
	movia r11, TIMER

	#Load HEX Address
	movia r9, HEX

	#set up PS 2 keyboard
	movia r12, PS_2_KEYBOARD

	#set up LEDs
	movi r17, 0x1
	movia  r16, RED_LEDS          # r16 and r17 are temporary values
	#stwio  r17, 0(r16)

	#Set up direction register
	movia	r8,	ADDR_JP1
	movia	r13,	0x07f557ff		#set direction for motors and sensors to output and sensor data registers to inputs
	stwio	r13,	4(r8)

	first:
	movia	r13,	LOAD_SENSOR0_THRESHOLD #Load the threshhold on sensor0
	stwio	r13,	0(r8) #write the value
	movia	r13,	LOAD_SENSOR0_THRESHOLD #Load the threshhold on sensor0
	stwio	r13,	0(r8) #write the value
	movia	r13,	MOTORS_STOP #Hex code for setting motors in forward direction with sensor 0 on
	stwio	r13,	0(r8) #write the value


	movia	r13,	LOAD_SENSOR1_THRESHOLD #Load the threshhold on sensor1
	stwio	r13,	0(r8) #write the value
	movia	r13,	LOAD_SENSOR1_THRESHOLD #Load the threshhold on sensor1
	stwio	r13,	0(r8) #write the value
	movia	r13,	MOTORS_STOP #Hex code for setting motors in forward direction with sensor 0 on
	stwio	r13,	0(r8) #write the value

	#Set up hex with 0 value
	movia r4, 0
	movia r5,0
	call display_hex_number

	movia r5,1
	call display_hex_number

	call Enable_Interrupts

SETUP_TIMER:

	addi  r9, r0, 0x8                   # stop the counter
	stwio r9, TIMER0_CONTROL(r11)

	#Set up the period registers
	addi  r9, r0, %lo (TICKSPERSEC)
	stwio r9, TIMER0_PERIODL(r11)
	addi  r9, r0, %hi(TICKSPERSEC)
	stwio r9, TIMER0_PERIODH(r11)

	#Reset the timer device
	stwio r0, TIMER0_STATUS(r11)

	#Start the timer with proper configuration
	addi  r9, r0, 0x5                   # 0x4 = 0101 so we write 1 to START but not to continue
	stwio r9, TIMER0_CONTROL(r11)

LOOPBOOP:
	br LOOPBOOP


#################################### FUNCTIONS #####################################

#Function responsible for displaying a number on the appropriate hex display
#R4 contains the value of the number to be displayed
#R5 contains the hex display to draw on
display_hex_number:

	#allocate space on the stack
	subi sp,sp,16

	#Save registers
	stw r13, 0(sp)
	stw r14, 4(sp)
	stw r15, 8(sp)
	stw r16, 12(sp)

	#Load HEX Address
	movia r9, HEX

	#determine shift for hex value
	muli r16,r5,7
	add r16, r16, r5

	#Switch statement implementation to determine binary of hex number to be drawn
	case0:
		cmpeqi r15, r4, 0
		beq r15,r0,case1
		movia r14, HEX_ZERO
		br break_switch

	case1:
		cmpeqi r15, r4, 1
		beq r15,r0,case2
		movia r14, HEX_ONE
		br break_switch

	case2:
		cmpeqi r15, r4, 2
		beq r15,r0,case3
		movia r14, HEX_TWO
		br break_switch

	case3:
		cmpeqi r15, r4, 3
		beq r15,r0,case4
		movia r14, HEX_THREE
		br break_switch

	case4:
		cmpeqi r15, r4, 4
		beq r15,r0,case5
		movia r14, HEX_FOUR
		br break_switch

	case5:
		cmpeqi r15, r4, 5
		beq r15,r0,case6
		movia r14, HEX_FIVE
		br break_switch

	case6:
		cmpeqi r15, r4, 6
		beq r15,r0,case7
		movia r14, HEX_SIX
		br break_switch

	case7:
		cmpeqi r15, r4, 7
		beq r15,r0,case8
		movia r14, HEX_SEVEN
		br break_switch

	case8:
		cmpeqi r15, r4, 8
		beq r15,r0,case9
		movia r14, HEX_EIGHT
		br break_switch

	case9:
		cmpeqi r15, r4, 0
		beq r15,r0,break_switch
		movia r14, HEX_NINE
		br break_switch


	break_switch:
	#Load the current status
	ldwio r13, 0(r9)

	#Shift the binary number to the appropriate location
	sll r14,r14,r16

	#Get the zeroes in the right position
	movi r15, 0xFFFFFF80
	rol r15, r15, r16

	#Update the HEX Display Properly
	and r13,r13,r15
	or r13,r13,r14

	#Display the new value on the hex display
	stwio r13, 0(r9)

	#Restore the registers from stack
	ldw r13, 0(sp)
	ldw r14, 4(sp)
	ldw r15, 8(sp)
	ldw r16, 12(sp)

	#Deallocate memory from stack
	addi sp,sp,16
ret


#Function that runs when someone wins, turns off interrupts and resets variables
#Useful when someone has won or hard reset the game
reset_game:
#Reset Counters
movi r18, 0
movi r19, 0

#Reset HEX Displays
#Set up hex with 0 value
	movia r4, 0
	movia r5,0
	call display_hex_number

	movia r5,1
	call display_hex_number

#Disable movement and scoreboard until game start enabled
call Disable_Device_Interrupts
ret


#Function that pauses game temporarily, useful for when robot gets knocked out
#Key0 starts a round ie devices start working again
temp_halt_game:
	call Disable_Device_Interrupts
ret


#Function to enable all interrupts
enable_interrupts:
	#enable interrupts in JTAG device
	movi r13, 0x00000001
	stwio r13, 4(r10)

	#enable interrupts on Lego device
	movia r13, 0b00011000000000000000000000000000  #enable interrupts for sensor 0
	stwio	r13,	8(r8)

	#enable interrupts on PS2 keyboard device
	movia r13, 0b01
	stwio	r13,	4(r12)

	#Mask IRQ line bits for processor TIMER IS BIT 0 and Lego controller (JP2) is bit 12, keyboard bit 7, JTAG UART is bit 8
    movi r13, 0b01000110000000 #timer currently disabled
    wrctl ienable, r13

    #Enable global interrupts for processor
    movi r13, 0x0000001
    wrctl status, r13
ret


#Function to disable interrupts from device
#Useful for disable user control temporarily
disable_device_interrupts:

	#enable interrupts in JTAG device
	movi r13, 0x00000000
	stwio r13, 4(r10)

	#enable interrupts on Lego device
	movia r13, 0b00000000000000000000000000000000  #enable interrupts for sensor 0
	stwio	r13,	8(r8)

	#enable interrupts on PS2 keyboard device
	movia r13, 0b00
	stwio	r13,	4(r12)
ret
