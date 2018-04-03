# r10 - JTAG keyboard
# r11 - Timer
# r8 - Lego controller

# r13, r14, r16, 17 - temp

.global	_start

	.equ ADDR_JP1,0xFF200070
	.equ MOTORS_BACKWARDS , 0b11111101010111111111111111110000
	.equ MOTORS_FORWARD ,   0b11111101010111111111111111111010 
	.equ MOTORS_FORWARD_LEFT,   0b11111101010111111111111111110110 
	.equ MOTORS_FORWARD_RIGHT ,   0b11111101010111111111111111111001
	.equ MOTORS_BACKWARDS_LEFT , 0b11111101010111111111111111110100
	.equ MOTORS_BACKWARDS_RIGHT , 0b11111101010111111111111111110001
	.equ MOTORS_LEFT , 0b11111101010111111111111111110010
	.equ MOTORS_RIGHT ,   0b11111101010111111111111111111000 
	.equ MOTORS_STOP ,   0b11111101010111111111111111110101 

	.equ LOAD_SENSOR0_THRESHOLD ,   0b11111100000111111111101111111111 

	.equ JTAG, 0xFF201000

	.equ TIMER, 0xFF202000 
	.equ  TIMER0_STATUS,    0
	.equ  TIMER0_CONTROL,   4
	.equ  TIMER0_PERIODL,   8
	.equ  TIMER0_PERIODH,   12
	.equ  TIMER0_SNAPL,     16
	.equ  TIMER0_SNAPH,     20
	.equ  TICKSPERSEC,      5000000

	.equ RED_LEDS, 0xFF200000 	   # (From DESL website > NIOS II > devices)
	
	.equ left_back_1, 0x31
	.equ back_2, 0x32
	.equ right_back_3, 0x33
	.equ left_4, 0x34
	.equ stop_5, 0x35
	.equ right_6, 0x36
	.equ left_forward_7, 0x37
	.equ forward_8, 0x38
	.equ right_forward_9, 0x39

#Interrupt Handler
.section .exceptions, "ax"
myISR:
	#allocate space on stack
	subi sp,sp,20 
	
	#Store registers modified
	stw r13,0(sp)
	stw r14,4(sp)
	stw r9,8(sp)
	stw r23,12(sp)
	stw ea,16(sp)

	rdctl r14, ipending
	
	#DETERMINE WHAT CASUED THE INTERRUPT

	#JTAG Interrupt
	add r13, r14, r0
	andi r13 ,r13, 0b0100000000
	movi r9, 0b0100000000
	beq r13,r9,JTAG_INTERRUPT
	
	#Timer Interrupt
	add r13, r14, r0
	andi r13 ,r13, 0x00000001
	movi r9, 0x00000001
	beq r13,r9,TIMER_INTERRUPT

	#Sensor Interrupt
	add r13, r14, r0
	andi r13 ,r13, 0b01000000000000
	movi r9, 0b01000000000000
	beq r13,r9,SENSOR_INTERRUPT

SENSOR_INTERRUPT:
#STOP EVERYTHING NOW

	DETERMINE_SENSOR:
		ldwio r13, 0(r8)
		srli r13, r13, 27
		andi r13,r13,0x1
		
		#If senesor 0 was the reason then disable interupts forever
		beq r13,r0, TURN_OFF
		br RETURN

	TURN_OFF:
		movia r13, 0b00000000000000000000000000000000  #DISABLE interrupts for sensor 0
		stwio	r13,	8(r8)

		movia r13, MOTORS_STOP
		stwio r13, 0(r8)
		br RETURN

JTAG_INTERRUPT:
#Read some information now from JTAG
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
		movia	r13,	MOTORS_BACKWARDS #Run the motors backwards
		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_robot1:
		movia	r13,	MOTORS_FORWARD #Run the motors forward
		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_LEFT_robot1:
		movia	r13,	MOTORS_FORWARD_LEFT #make a curved left turn forward
		stwio	r13,	0(r8) #write the value
		br RETURN

	FORWARD_RIGHT_robot1:
		movia	r13,	MOTORS_FORWARD_RIGHT #Run the motors backwards
		stwio	r13,	0(r8) #write the value
		br RETURN

	LEFT_robot1:
		movia	r13,	MOTORS_LEFT #Run the motors forward
		stwio	r13,	0(r8) #write the value
		br RETURN

	RIGHT_robot1:
		movia	r13,	MOTORS_RIGHT #make a curved left turn forward
		stwio	r13,	0(r8) #write the value
		br RETURN

	BACKWARDS_LEFT_robot1:
		movia	r13,	MOTORS_BACKWARDS_LEFT #Run the motors backwards
		stwio	r13,	0(r8) #write the value
		br RETURN

	BACKWARDS_RIGHT_robot1:
		movia	r13,	MOTORS_BACKWARDS_RIGHT #Run the motors forward
		stwio	r13,	0(r8) #write the value
		br RETURN

	STOP_robot1:
		movia	r13,	MOTORS_STOP #Stop the motors
		stwio	r13,	0(r8) #write the value
		br RETURN
	
TIMER_INTERRUPT:
br RETURN

RETURN:
	#restore registers modified
	ldw r13,0(sp)
	ldw r14,4(sp)
	ldw r9,8(sp)
	ldw r23,12(sp)
	ldw ea,16(sp)

	#deallocate space on stack
	addi sp,sp,20 

subi ea,ea,4
eret

_start:
	#Initialize stack pointer
	movia sp, 0x03FFFFFC
	
	#set up JTAG and timer
	movia r10, JTAG
	movia r11, TIMER

	#set up LEDs 
	movi r17, 0x1
	movia  r16, RED_LEDS          # r16 and r17 are temporary values
	stwio  r17, 0(r16)

	#Set up direction register
	movia	r8,	ADDR_JP1
	movia	r13,	0x07f557ff		#set direction for motors and sensors to output and sensor data registers to inputs
	stwio	r13,	4(r8)

	first:
	movia	r13,	LOAD_SENSOR0_THRESHOLD #Load the threshhold on sensor0
	stwio	r13,	0(r8) #write the value
	movia	r13,	MOTORS_STOP #Hex code for setting motors in forward direction with sensor 0 on
	stwio	r13,	0(r8) #write the value

ENABLE_INTERRUPTS:
	#enable interrupts in JTAG device
	movi r13, 0x00000001
	stwio r13, 4(r10)

	#enable interrupts on Lego device
	movia r10, 0b00001000000000000000000000000000  #enable interrupts for sensor 0
	stwio	r10,	8(r8)

	#Mask IRQ line bits for processor TIMER IS BIT 0 and Lego controller is bit 8
    movi r13, 0b00000100000000
    wrctl ienable, r13

    #Enable global interrupts for processor
    movi r13, 0x0000001
    wrctl status, r13

SETUP_TIMER:
	
	# stop the counter
	addi  r9, r0, 0x8
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




