/******************************************************************************
Filename    : rmp_platform_avr.c
Author      : pry
Date        : 04/02/2018
Licence     : The Unlicense; see LICENSE for details.
Description : The platform specific file for AVR.
******************************************************************************/

/* Include *******************************************************************/
#define __HDR_DEF__
#include "Platform/AVR/rmp_platform_avr.h"
#include "Kernel/rmp_kernel.h"
#undef __HDR_DEF__

#define __HDR_STRUCT__
#include "Platform/AVR/rmp_platform_avr.h"
#include "Kernel/rmp_kernel.h"
#undef __HDR_STRUCT__

/* Private include */
#include "Platform/AVR/rmp_platform_avr.h"

#define __HDR_PUBLIC__
#include "Kernel/rmp_kernel.h"
#undef __HDR_PUBLIC__
/* End Include ***************************************************************/

/* Function:_RMP_Stack_Init ***************************************************
Description : Initiate the process stack when trying to start a process. Never
              call this function in user application.
Input       : rmp_ptr_t Stack - The stack address of the thread.
              rmp_ptr_t Size - The stack size of the thread.
              rmp_ptr_t Entry - The entry address of the thread.
              rmp_ptr_t Param - The argument to pass to the thread.
Output      : None.
Return      : rmp_ptr_t - The adjusted stack location.
******************************************************************************/
rmp_ptr_t _RMP_Stack_Init(rmp_ptr_t Stack,
                          rmp_ptr_t Size,
                          rmp_ptr_t Entry,
                          rmp_ptr_t Param)
{
    struct RMP_AVR_Stack* Ptr;
    
    /* Compute stack - empty descending, no alignment requirement */
    Ptr=(struct RMP_AVR_Stack*)(Stack+Size-sizeof(struct RMP_AVR_Stack)-1U);
    
    /* Set SREG to all zero for MegaAVR which uses RETI to set GIE, but set
     * GIE on XMegaAVR which uses PMIC to take care of interrupt nesting */
#if(RMP_AVR_COP_XMEGA!=0U)
    Ptr->SREG_SR=0x80U;
#else
    Ptr->SREG_SR=0x80U;
#endif
    
    /* Pass entry and parameter - program space is in words instead of bytes */
    Ptr->PCH=Entry>>8;
    Ptr->PCL=Entry&0xFFU;
    Ptr->R25=Param>>8;
    Ptr->R24=Param&0xFFU;
    
    /* Fill the rest for ease of identification */
    Ptr->R0=0x00U;
    Ptr->R1=0x01U;
    Ptr->R2=0x02U;
    Ptr->R3=0x03U;
    Ptr->R4=0x04U;
    Ptr->R5=0x05U;
    Ptr->R6=0x06U;
    Ptr->R7=0x07U;
    Ptr->R8=0x08U;
    Ptr->R9=0x09U;
    Ptr->R10=0x10U;
    Ptr->R11=0x11U;
    Ptr->R12=0x12U;
    Ptr->R13=0x13U;
    Ptr->R14=0x14U;
    Ptr->R15=0x15U;
    Ptr->R16=0x16U;
    Ptr->R17=0x17U;
    Ptr->R18=0x18U;
    Ptr->R19=0x19U;
    Ptr->R20=0x20U;
    Ptr->R21=0x21U;
    Ptr->R22=0x22U;
    Ptr->R23=0x23U;
    Ptr->R26_XL=0x00U;
    Ptr->R27_XH=0x00U;
    Ptr->R28_YL=0x00U;
    Ptr->R29_YH=0x00U;
    Ptr->R30_ZL=0x00U;
    Ptr->R31_ZH=0x00U;

    /* EIND implies RAMP */
#if((RMP_AVR_COP_RAMP!=0U)||(RMP_AVR_COP_EIND!=0U))
    Ptr->RAMPD_ZU=0x00U;
    Ptr->RAMPX_XU=0x00U;
    Ptr->RAMPY_YU=0x00U;
    Ptr->RAMPZ_ZU=0x00U;
#endif

#if(RMP_AVR_COP_EIND!=0U)
    Ptr->EIND_ZU=0x00U;
    Ptr->PCU=0x00U;
#endif
    
    /* Empty descending */
    return ((rmp_ptr_t)Ptr)-1U;
}
/* End Function:_RMP_Stack_Init **********************************************/

/* Function:_RMP_Lowlvl_Init **************************************************
Description : Initialize the low level hardware of the system.
Input       : None
Output      : None.
Return      : None.
******************************************************************************/
void _RMP_Lowlvl_Init(void)
{
    RMP_Int_Disable();
    
    RMP_AVR_LOWLVL_INIT();
}
/* End Function:_RMP_Lowlvl_Init *********************************************/

/* Function:_RMP_Plat_Hook ****************************************************
Description : Platform-specific hook for system initialization.
Input       : None
Output      : None.
Return      : None.
******************************************************************************/
void _RMP_Plat_Hook(void)
{
    /* Scheduler lock implemented with interrupt disabling */
}
/* End Function:_RMP_Plat_Hook ***********************************************/

/* Function:RMP_Putchar *******************************************************
Description : Print a character to the debug console.
Input       : char Char - The character to print.
Output      : None.
Return      : None.
******************************************************************************/
void RMP_Putchar(char Char)
{
    RMP_AVR_PUTCHAR(Char);
}
/* End Function:RMP_Putchar **************************************************/

/* Function:_RMP_Yield ********************************************************
Description : Trigger a yield to another thread.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
void _RMP_Yield(void)
{
    if(RMP_AVR_Int_Act!=0U)
        _RMP_AVR_Yield_Pend=1U;
    else
        /* EIND implies RAMP */
#if(RMP_AVR_COP_XMEGA==0U)
#if(RMP_AVR_COP_EIND!=0U)
        _RMP_AVR_Yield_MEGA_EIND();
#elif(RMP_AVR_COP_RAMP!=0U)
        _RMP_AVR_Yield_MEGA_RAMP();
#else
        _RMP_AVR_Yield_MEGA();
#endif
#else
#if(RMP_AVR_COP_EIND!=0U)
        _RMP_AVR_Yield_XMEGA_EIND();
#elif(RMP_AVR_COP_RAMP!=0U)
        _RMP_AVR_Yield_XMEGA_RAMP();
#else
        _RMP_AVR_Yield_XMEGA();
#endif
#endif
}
/* End Function:_RMP_Yield ***************************************************/

/* Function:_RMP_AVR_Tim_Handler **********************************************
Description : Timer interrupt routine for DSPIC.
Input       : None
Output      : None.
Return      : None.
******************************************************************************/
void _RMP_AVR_Tim_Handler(void)
{
    RMP_AVR_TIM_CLR();

    _RMP_Tim_Handler(1U);
}
/* End Function:_RMP_AVR_Tim_Handler *****************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
