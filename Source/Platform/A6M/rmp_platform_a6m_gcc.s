/******************************************************************************
Filename    : rmp_platform_cm0_asm_gcc.s
Author      : pry
Date        : 10/04/2012
Description : The assembly part of the RMP RTOS. This is for Cortex-M0/0+/1.
******************************************************************************/

/* The ARM Cortex-M0 Architecture *********************************************
R0-R7:General purpose registers that are accessible. 
R8-R12:General purpose registers that can only be reached by 32-bit instructions.
R13:SP/SP_process/SP_main    Stack pointer
R14:LR                       Link Register(used for returning from a subfunction)
R15:PC                       Program counter.
IPSR                         Interrupt Program Status Register.
APSR                         Application Program Status Register.
EPSR                         Execute Program Status Register.
The above 3 registers are saved into the stack in combination(xPSR).
******************************************************************************/

/* Import ********************************************************************/
    /* The real task switch handling function */
    .extern             _RMP_Run_High
    /* The real systick handler function */
    .extern             _RMP_Tim_Handler
    /* The PID of the current thread */
    .extern             RMP_Thd_Cur
    /* The stack address of current thread */
    .extern             RMP_SP_Cur
/* End Import ****************************************************************/

/* Export ********************************************************************/
    /* Disable all interrupts */
    .global             RMP_Int_Disable
    /* Enable all interrupts */
    .global             RMP_Int_Enable
    /* Mask/unmask interrupt dummy */
    .global             RMP_Int_Mask
    /* Start the first thread */
    .global             _RMP_Start
    /* The PendSV trigger */
    .global             _RMP_Yield
    /* The system pending service routine */
    .global             PendSV_Handler
    /* The systick timer routine */
    .global             SysTick_Handler
/* End Export ****************************************************************/

/* Header ********************************************************************/
    .section            ".text.arch"
    .syntax             unified
    .thumb
    .align              3
/* End Header ****************************************************************/

/* Function:RMP_Int_Disable ***************************************************
Description : The function for disabling all interrupts. Does not allow nesting.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
RMP_Int_Disable:
    CPSID               I
    BX                  LR
/* End Function:RMP_Int_Disable **********************************************/

/* Function:RMP_Int_Enable ****************************************************
Description : The function for enabling all interrupts. Does not allow nesting.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
RMP_Int_Enable:
    CPSIE               I               
    BX                  LR
/* End Function:RMP_Int_Enable ***********************************************/

/* Function:RMP_Int_Mask ******************************************************
Description : Cortex-M0 does not allow masking and this is provided as dummy.
Input       : rmp_ptr_t R0 - The new BASEPRI to set.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
RMP_Int_Mask:
    BX                  LR
/* End Function:RMP_Int_Mask *************************************************/

/* Function:_RMP_Yield ********************************************************
Description : Trigger a yield to another thread.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
_RMP_Yield:
    LDR                 R0,=0xE000ED04      /* The NVIC_INT_CTRL register */
    LDR                 R1,=0x10000000      /* Trigger the PendSV */
    STR                 R1,[R0]
    ISB                                     /* Instruction barrier */
    BX                  LR         
/* End Function:_RMP_Yield ***************************************************/

/* Function:_RMP_Start ********************************************************
Description : Jump to the user function and will never return from it.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
_RMP_Start:
    MSR                 PSP,R1              /* Set the stack pointer */
    MOVS                R4,#0x02            /* Previleged thread mode */
    MSR                 CONTROL,R4
    ISB                                     /* Data and instruction barrier */
    BLX                 R0                  /* Branch to our target */
/* End Function:_RMP_Start ***************************************************/

/* Function:PendSV_Handler ****************************************************
Description : The PendSV interrupt routine. In fact, it will call a C function
              directly. The reason why the interrupt routine must be an assembly
              function is that the compiler may deal with the stack in a different
              way when different optimization level is chosen. An assembly function
              can make way around this problem.
              However, if your compiler support inline assembly functions, this
              can also be written in C.
              ARMv6-M only have STMIA, will have to live with it.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
PendSV_Handler:
    MRS                 R0,PSP              /* Save all the registers onto the user stack */
    SUBS                R0,#36
    MOV                 R1,R0
    STMIA               R1!,{R4-R7}         /* Save low register first due to limitation */
    MOV                 R7,LR
    MOV                 R6,R11
    MOV                 R5,R10
    MOV                 R4,R9
    MOV                 R3,R8
    STMIA               R1!,{R3-R7}

    LDR                 R1,=RMP_SP_Cur      /* Save The SP to control block */
    STR                 R0,[R1]
    BL                  _RMP_Run_High       /* Get the highest ready task */
    LDR                 R1,=RMP_SP_Cur      /* Load the SP */
    LDR                 R0,[R1]

    MOV                 R1,R0               /* Load all the registers from the user stack */
    ADDS                R0,#16
    LDMIA               R0!,{R3-R7}         /* Load high registers first due to limitation */
    MOV                 R8,R3
    MOV                 R9,R4
    MOV                 R10,R5
    MOV                 R11,R6
    MOV                 LR,R7
    LDMIA               R1!,{R4-R7}
    MSR                 PSP,R0

    BX                  LR
/* End Function:PendSV_Handler ***********************************************/

/* Function:SysTick_Handler ***************************************************
Description : The SysTick interrupt routine. In fact, it will call a C function
              directly. The reason why the interrupt routine must be an assembly
              function is that the compiler may deal with the stack in a different
              way when different optimization level is chosen. An assembly function
              can make way around this problem.
              However, if your compiler support inline assembly functions, this
              can also be written in C.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
SysTick_Handler:
    PUSH                {LR}
    
    MOVS                R0,#0x01            /* We are not using tickless. */
    BL                  _RMP_Tim_Handler
    
    POP                 {PC}
/* End Function:SysTick_Handler **********************************************/

    .end
/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
