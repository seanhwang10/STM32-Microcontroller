.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

//==================================================================
// ECE 362 Lab Experiment 5
// Timers
//==================================================================

// RCC configuration registers
.equ  RCC,      0x40021000
.equ  AHBENR,   0x14
.equ  GPIOCEN,  0x00080000
.equ  GPIOBEN,  0x00040000
.equ  GPIOAEN,  0x00020000
.equ  APB1ENR,  0x1c
.equ  TIM6EN,   1<<4
.equ  TIM7EN,   1<<5

// NVIC configuration registers
.equ NVIC, 0xe000e000
.equ ISER, 0x100
.equ ICER, 0x180
.equ ISPR, 0x200
.equ ICPR, 0x280
.equ IPR,  0x400
.equ TIM6_DAC_IRQn, 17
.equ TIM7_IRQn,     18

// Timer configuration registers
.equ TIM6, 0x40001000
.equ TIM7, 0x40001400
.equ TIM_CR1,  0x00
.equ TIM_CR2,  0x04
.equ TIM_DIER, 0x0c
.equ TIM_SR,   0x10
.equ TIM_EGR,  0x14
.equ TIM_CNT,  0x24
.equ TIM_PSC,  0x28
.equ TIM_ARR,  0x2c

// Timer configuration register bits
.equ TIM_CR1_CEN,  1<<0
.equ TIM_DIER_UDE, 1<<8
.equ TIM_DIER_UIE, 1<<0
.equ TIM_SR_UIF,   1<<0

// GPIO configuration registers
.equ  GPIOC,    0x48000800
.equ  GPIOB,    0x48000400
.equ  GPIOA,    0x48000000
.equ  MODER,    0x00
.equ  PUPDR,    0x0c
.equ  IDR,      0x10
.equ  ODR,      0x14
.equ  BSRR,     0x18
.equ  BRR,      0x28

//==========================================================================
// enable_ports  (Autotest 1)
// Enable RCC clock for GPIO ports B and C.
// Parameters: none
// Return value: none
.global enable_ports
enable_ports:
	push {lr}
	// Student code goes below
    ldr r0, =RCC
    ldr r1, [r0, #AHBENR]
    ldr r2, =GPIOBEN
    orrs r1, r2
    ldr r2, =GPIOCEN
    orrs r1, r2
    str r1, [r0, #AHBENR]

    ldr r0, =GPIOB
    ldr r1, [r0, #MODER]
    ldr r2, =0xFFFF
    bics r1, r2
    ldr r2, =0x55
    orrs r1, r2
    str r1, [r0, #MODER]

    ldr r1, [r0, #PUPDR]
    ldr r2, =0xFF00
    bics r1, r2
    ldr r2, =0xAA00
    orrs r1, r2
    str r1, [r0, #PUPDR]

    ldr r0, =GPIOC
    ldr r1, [r0, #MODER]
    ldr r2, =0x3FFFFF
    bics r1, r2
    ldr r2, =0x155555
    orrs r1, r2
    str r1, [r0, #MODER]

	// Student code goes above
	pop  {pc}

//==========================================================================
// Timer 6 Interrupt Service Routine  (Autotest 2)
// Parameters: none
// Return value: none
// Write your entire subroutine below
.type TIM6_DAC_IRQHandler, %function
.global TIM6_DAC_IRQHandler
TIM6_DAC_IRQHandler:
    ldr r0, =TIM6
    ldr r1, [r0, #TIM_SR]
    ldr r2, =TIM_SR_UIF
    bics r1, r2
    str r1, [r0, #TIM_SR]

    movs r0, #6
    ldr r1, =GPIOC
    ldr r2, [r1, #ODR]
    movs r3, #1
    cmp r3, r0
    beq toggle1to0
toggle0to1:
    orrs r2, r0
    b togglestore
toggle1to0:
    bics r2, r0
togglestore:
    str r2, [r1,#ODR]
    bx lr


//==========================================================================
// setup_tim6  (Autotest 3)
// Configure timer 6
// Parameters: none
// Return value: none
.global setup_tim6
setup_tim6:
	push {lr}
	// Student code goes below
    ldr r0, =RCC
    ldr r1, [r0, #APB1ENR]
    ldr r2, =TIM6EN
    orrs r1, r2
    str r1, [r0, #APB1ENR]

    ldr r0, =TIM6
    ldr r1, =48000-1

    ldr r1, [r0, #TIM_CR1]
    ldr r2, =TIM_CR1_CEN
    orrs r1, r2
    str r1, [r0, #TIM_CR1]

    ldr r0, =NVIC
    ldr r1, =ISER
    ldr r2, =(1<<TIM6_DAC_IRQn)
    str r2, [r0, r1]

	// Student code goes above
	pop  {pc}

.data
.global display
display: .byte 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07
.global history
history: .space 16
.global offset
offset: .byte 0
.text

//==========================================================================
// show_digit  (Autotest 4)
// Setup Port C outputs to show the digit for the current
// value of the offset variable.
// Parameters: none
// Return value: none
// Write your entire subroutine below.

.global show_digit
show_digit:
    push {lr}
    ldr r0, =offset
    ldr r0, [r0]	// r0 = offset
    movs r1, #7
    orrs r0, r3
    ldr r1, =GPIOC
    str r0, [r1, #ODR]
    pop {pc}

//==========================================================================
// get_cols  (Autotest 5)
// Return the current value of the PC8 - PC4 pins.
// Parameters: none
// Return value: 4-bit result of columns active for the selected row
// Write your entire subroutine below.
.global get_cols
get_cols:
    push {lr}
    ldr r0, =GPIOB
    ldr r1, [r0, #IDR]
    lsrs r1, r1, #4
    ldr r2, =0xF
    pop {pc}

//==========================================================================
// update_hist  (Autotest 6)
// Update history byte entries for the current row.
// Parameters: r0: cols: 4-bit value read from matrix columns
// Return value: none
// Write your entier subroutine below.
.global update_hist
update_hist:
    push {r4, r5, r6, lr}
    ldr r1, =offset
    ldr r1, [r1]
upfor:
    cmp r2, #4
    bge upendfor
upbody:
    movs r3, #4
    muls r3, r1     //r3 = 4*row
    adds r3, r2     //r3 = 4*row+i
    ldr r4, =history
    ldrb r5, [r4, r3] // r5 = history[4*row+i]
    cmp r5, #0
    beq upendif
    ldrb r5, [r4, r3]
    movs r6, #1
upendif:
    adds r2, #1
    b upfor
upendfor:
    pop {r4, r5, r6, pc}



//==========================================================================
// set_row  (Autotest 7)
// Set PB3 - PB0 to represent the row being scanned.
// Parameters: none
// Return value: none
// Write your entire subroutine below.
.global set_row
set_row:
    push {lr}
    ldr r0, =offset
    ldr r0, [r0]	// r0 = offset
    movs r1, #3
    ldr r0, =0xf0000
    orrs r0, r1
    ldr r1, =GPIOB
    str r0, [r1, #BSRR]
    pop {pc}

//==========================================================================
// Timer 7 Interrupt Service Routine  (Autotest 8)
// Parameters: none
// Return value: none
// Write your entire subroutine below

.type TIM7_IRQHandler, %function
.global TIM7_IRQHandler
TIM7_IRQHandler:
	push {lr}
    ldr r0, =TIM7
    ldr r1, [r0, #TIM_SR]
    ldr r2, =TIM_SR_UIF
    bics r1, r2
    str r1, [r0, #TIM_SR]

    bl show_digit
    bl get_cols
    bl update_hist

    ldr r0, =offset
    str r1, [r0]
    bl set_row
	pop {pc}
//==========================================================================
// setup_tim7  (Autotest 9)
// Configure Timer 7.
// Parameters: none
// Return value: none
.global setup_tim7
setup_tim7:
	push {lr}
    ldr r0, =RCC
    ldr r1, [r0, #APB1ENR]
    ldr r2, =TIM6EN
    bics r1, r2
    ldr r2, =TIM7EN
    orrs r1, r2
    str r1, [r0, #APB1ENR]

    ldr r0, =NVIC
    ldr r1, =ISER
    ldr r2, =(1<<TIM7_IRQn)
    str r2, [r0, r1]


	pop  {pc}


//==========================================================================
// get_keypress  (Autotest 10)
// Wait for and return the number (0-15) of the ID of a button pressed.
// Parameters: none
// Return value: button ID
.global get_keypress
get_keypress:
	push {lr}
	// Student code goes below
ginfinite:
wait:
    wfi
gif:
    ldr r0, =offset
    ldr r0, [r0]
    cmp r0, #0
    bne wait
    ldr r0, =history
    movs r1, #0
gfor:
    cmp r1, #16
    bge endgfor
    bne gendif
    movs r0, r1
    b gpop
gendif:
    adds r1, #1
    b gfor
endgfor:
	b ginfinite
gpop:
	// Student code goes above
	pop {pc}

//==========================================================================
// handle_key  (Autotest 11)
// Shift all symbols in the display left and add a new digit
// in the rightmost digit.
// ALSO: Create your "font" array just above.
// Parameters: ID of new button to display
// Return value: none

font: .byte 0x06, 0x5b, 0x4f, 0x77, 0x66, 0x6d, 0x7d, 0x7c, 0x07, 0x7f, 0x67, 0x39, 0x49, 0x3f, 0x76, 0x5e

.global handle_key
handle_key:
	push {lr}
	// Student code goes below
    ldr r1, =0xF
    ands r0, r1
    movs r1, #0
    ldr r2, =display
hfor:
    cmp r1, #7
    bge endhfor
    strb r5, [r2, r3]
    adds r1, #1
    b hfor
endhfor:
    ldr r1, =font
    ldrb r3, [r1, r0]
    ldr r1, =display
    strb r3, [r1, r0]
	// Student code goes above
	pop  {pc}

.global login
login: .string "hwang103"
.align 2

//==========================================================================
// main
// Already set up for you.
// It never returns.
.global main
main:
	//bl  check_wiring
	bl  autotest
	bl  enable_ports
	bl  setup_tim6
	bl  setup_tim7

endless_loop:
	bl   get_keypress
	bl   handle_key
	b    endless_loop
