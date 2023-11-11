/******************************************************************************
Filename    : rmp_test_stm32f030f4.h
Author      : pry 
Date        : 22/07/2017
Licence     : The Unlicense; see LICENSE for details.
Description : The testbench for STM32F030F4.

ARMCC V6.14 -Oz 
    ___   __  ___ ___
   / _ \ /  |/  // _ \       Simple real-time kernel
  / , _// /|_/ // ___/       Standard benchmark test
 /_/|_|/_/  /_//_/
====================================================
Test (number in CPU cycles)        : AVG / MAX / MIN
Yield                              : 362 / 465 / 353
Mailbox                            : 763 / 852 / 739
Semaphore                          : 666 / 765 / 649
FIFO                               : 379 / 776 / 368
Message queue                      : 1196 / 1279 / 1164
Blocking message queue             : 1609 / 1672 / 1578
ISR Mailbox                        : 689 / 786 / 668
ISR Semaphore                      : 616 / 720 / 604
ISR Message queue                  : 950 / 1041 / 923
ISR Blocking message queue         : 1211 / 1292 / 1174
******************************************************************************/

/* Includes ******************************************************************/
#include "rmp.h"
/* End Includes **************************************************************/

/* Defines *******************************************************************/
/* How to read counter */
#define RMP_CNT_READ()    (TIM3->CNT)
/* Are we doing minimal measurements? */
/* #define MINIMAL_SIZE */
/* The STM32F0 timers are all 16 bits, so */
typedef rmp_u16_t rmp_tim_t;
/* End Defines ***************************************************************/

/* Globals *******************************************************************/
#ifndef MINIMAL_SIZE
rmp_ptr_t Stack_1[128];
rmp_ptr_t Stack_2[128];
TIM_HandleTypeDef TIM3_Handle={0};
TIM_HandleTypeDef TIM14_Handle={0};

void Timer_Init(void);
void Int_Init(void);
void Int_Handler(void);
void HAL_TIM_Base_MspInit(TIM_HandleTypeDef *htim);
void TIM14_IRQHandler(void);
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
    /* TIM3 clock = CPU clock */
    TIM3_Handle.Instance=TIM3;
    TIM3_Handle.Init.Prescaler=0;
    TIM3_Handle.Init.CounterMode=TIM_COUNTERMODE_UP;
    TIM3_Handle.Init.Period=(rmp_u16_t)(-1);
    TIM3_Handle.Init.ClockDivision=TIM_CLOCKDIVISION_DIV1;
    HAL_TIM_Base_Init(&TIM3_Handle);
    __HAL_RCC_TIM3_CLK_ENABLE();
    __HAL_TIM_ENABLE(&TIM3_Handle);
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
    /* TIM14 clock = CPU clock */
    TIM14_Handle.Instance=TIM14;
    TIM14_Handle.Init.Prescaler=0;
    TIM14_Handle.Init.CounterMode=TIM_COUNTERMODE_DOWN;
    TIM14_Handle.Init.Period=3600;
    TIM14_Handle.Init.ClockDivision=TIM_CLOCKDIVISION_DIV1;
    HAL_TIM_Base_Init(&TIM14_Handle);
    __HAL_RCC_TIM14_CLK_ENABLE();
    __HAL_TIM_ENABLE(&TIM14_Handle);
    /* Clear interrupt pending bit, because we used EGR to update the registers */
    __HAL_TIM_CLEAR_IT(&TIM14_Handle, TIM_IT_UPDATE);
    HAL_TIM_Base_Start_IT(&TIM14_Handle);
}

void HAL_TIM_Base_MspInit(TIM_HandleTypeDef *htim)
{
    if(htim->Instance==TIM14) 
    {
        /* Set the interrupt priority */
        NVIC_SetPriority(TIM14_IRQn,0xFF);
        /* Enable timer 21 interrupt */
        NVIC_EnableIRQ(TIM14_IRQn);
        /* Enable timer 21 clock */
        __HAL_RCC_TIM14_CLK_ENABLE();
    }
}

/* The interrupt handler */
void TIM14_IRQHandler(void)
{
    TIM14->SR=~TIM_FLAG_UPDATE;
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
    /* Disable timer 14 interrupt */
    NVIC_DisableIRQ(TIM14_IRQn);
}
#endif
/* End Function:Int_Disable **************************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
