/******************************************************************************
Filename    : rmp_test_msp430fr5994.h
Author      : pry 
Date        : 22/07/2017
Licence     : The Unlicense; see LICENSE for details.
Description : The testbench for MSP430FR5994.
              This test is slow. It takes typ.1 min 30 sec to run @ 16MHz.

TICC V21.6.1LTS -O4 -mf5 (OS timer disabled)
    ___   __  ___ ___
   / _ \ /  |/  // _ \       Simple real-time kernel
  / , _// /|_/ // ___/       Standard benchmark test
 /_/|_|/_/  /_//_/
====================================================
Test (number in CPU cycles)        : AVG / MAX / MIN
Yield                              : 450 / 450 / 450
Mailbox                            : 977 / 977 / 977
Semaphore                          : 847 / 847 / 847
FIFO                               : 435 / 435 / 435
Message queue                      : 1443 / 1444 / 1443
Blocking message queue             : 1885 / 1885 / 1885
Memory allocation/free pair        : 3508 / 3620 / 3411
ISR Mailbox                        : 874 / 875 / 340
ISR Semaphore                      : 792 / 792 / 792
ISR Message queue                  : 1156 / 1156 / 1156
ISR Blocking message queue         : 1413 / 1413 / 1413

TICC V21.6.1LTS -O4 -mf5 (OS timer enabled)
    ___   __  ___ ___
   / _ \ /  |/  // _ \       Simple real-time kernel
  / , _// /|_/ // ___/       Standard benchmark test
 /_/|_|/_/  /_//_/
====================================================
Test (number in CPU cycles)        : AVG / MAX / MIN
Yield                              : 454 / 1589 / 449
Mailbox                            : 977 / 1577 / 974
Semaphore                          : 847 / 1462 / 846
FIFO                               : 436 / 1051 / 435
Message queue                      : 1442 / 1443 / 1442
Blocking message queue             : 1889 / 2501 / 1883
Memory allocation/free pair        : 3526 / 3679 / 3416
ISR Mailbox                        : 873 / 1475 / 339
ISR Semaphore                      : 793 / 1405 / 791
ISR Message queue                  : 1157 / 1770 / 1154
ISR Blocking message queue         : 1415 / 2029 / 1412
******************************************************************************/

/* Includes ******************************************************************/
#include "rmp.h"
/* End Includes **************************************************************/

/* Defines *******************************************************************/
/* Where are the initial stacks */
#define THD1_STACK          (&Stack_1[128])
#define THD2_STACK          (&Stack_2[128])
/* How to read counter */
#define RMP_CNT_READ()      (TA1R)
/* Are we testing the memory pool? */
#define TEST_MEM_POOL       (8192U)
#pragma PERSISTENT(Pool)
/* Are we doing minimal measurements? */
/* #define MINIMAL_SIZE */
/* The MSP430 timers are all 16 bits, so */
typedef rmp_u16_t rmp_tim_t;
/* End Defines ***************************************************************/

/* Globals *******************************************************************/
#ifndef MINIMAL_SIZE
rmp_ptr_t Stack_1[256];
rmp_ptr_t Stack_2[256];
struct Timer_A_initUpModeParam TIM1_Handle={0};

void Timer_Init(void);
void Int_Init(void);
void Int_Handler(void);
void Int_Disable(void);
/* End Globals ***************************************************************/

/* Begin Function:Timer_Init **************************************************
Description : Initialize the timer for timing measurements. This function needs
              to be adapted to your specific hardware.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
void Timer_Init(void)
{
    /* TIM1 clock = CPU clock */
    TIM1_Handle.clockSource=TIMER_A_CLOCKSOURCE_SMCLK;
    TIM1_Handle.clockSourceDivider=TIMER_A_CLOCKSOURCE_DIVIDER_1;
    TIM1_Handle.timerPeriod=0xFFFF;
    TIM1_Handle.timerInterruptEnable_TAIE=TIMER_A_TAIE_INTERRUPT_DISABLE;
    TIM1_Handle.captureCompareInterruptEnable_CCR0_CCIE=TIMER_A_CCIE_CCR0_INTERRUPT_DISABLE;
    TIM1_Handle.timerClear=TIMER_A_SKIP_CLEAR;
    TIM1_Handle.startTimer=1;
    Timer_A_initUpMode(TA1_BASE,&TIM1_Handle);
}
/* End Function:Timer_Init ***************************************************/

/* Begin Function:Int_Init ****************************************************
Description : Initialize an periodic interrupt source. This function needs
              to be adapted to your specific hardware.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
void Int_Init(void)
{
    /* Make sure that we also generate interrupts from the same timer */
    TA1CCTL0|=CCIE;
}


/* The interrupt handler */
#pragma vector=TIMER1_A0_VECTOR
__interrupt void TIM1_IRQHandler(void)
{
    TA1CCTL0&=~CCIFG;
    Int_Handler();
}
/* End Function:Int_Init *****************************************************/

/* Begin Function:Int_Disable *************************************************
Description : Disable the periodic interrupt source. This function needs
              to be adapted to your specific hardware.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
void Int_Disable(void)
{
    /* Disable timer 1 interrupt */
    TA1CCTL0&=~CCIE;
}
#endif
/* End Function:Int_Disable **************************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/