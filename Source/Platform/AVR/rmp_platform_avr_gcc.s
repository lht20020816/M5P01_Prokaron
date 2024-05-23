/******************************************************************************
Filename    : rmp_platform_avr_gcc.s
Author      : pry
Date        : 10/04/2012
Description : The assembly part of the RMP RTOS. This is for AVR.
******************************************************************************/

/* The Atmel (Now Microchip) AVR Architecture *********************************
R0-R31      : General purpose registers, where
              R0 is the temporary register,
              R1 is the zero register (cleared by GCC after pollution),
              [R29:R28] is the frame pointer.
EIND        : Code address upper register used with Z for >128KiB code.
RAMPD       : Data address upper register used with Z for >64KiB data.
RAMPX       : Code & data address upper register used with X for >64KiB code/data.
RAMPY       : Code & data address upper register used with Y for >64KiB code/data.
RAMPZ       : Code & data address upper register used with Z for >64KiB code/data.
SP          : Stack pointer.
PC          : Program counter.
SREG        : Status Register.
PMIC_CTRL   : Only present in XMega series for interrupt masking.
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
    /* Kernel stack and table */
    .extern             _RMP_AVR_SP_Kern
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
    /* Trigger a context switch */
    .global             _RMP_AVR_Yield_MEGA
    .global             _RMP_AVR_Yield_MEGA_RAMP
    .global             _RMP_AVR_Yield_MEGA_EIND
    .global             _RMP_AVR_Yield_XMEGA
    .global             _RMP_AVR_Yield_XMEGA_RAMP
    .global             _RMP_AVR_Yield_XMEGA_EIND
/* End Export ****************************************************************/

/* Header ********************************************************************/
    .section            ".text.arch"
    .align              2

    /* CPU register definitions */
    .equ                RMP_RAMPD,0x38
    .equ                RMP_RAMPX,0x39
    .equ                RMP_RAMPY,0x3A
    .equ                RMP_RAMPZ,0x3B
    .equ                RMP_EIND,0x3C
    .equ                RMP_SPL,0x3D
    .equ                RMP_SPH,0x3E
    .equ                RMP_SREG,0x3F
    .equ                RMP_PMIC_CTRL,0xA2
/* End Header ****************************************************************/

/* Function:RMP_Int_Disable ***************************************************
Description : The function for disabling all interrupts. Does not allow nesting.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
RMP_Int_Disable:
    CLI
    RET
/* End Function:RMP_Int_Disable **********************************************/

/* Function:RMP_Int_Enable ****************************************************
Description : The function for enabling all interrupts. Does not allow nesting.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
RMP_Int_Enable:
    SEI
    RET
/* End Function:RMP_Int_Enable ***********************************************/

/* Function:RMP_Int_Mask ******************************************************
Description : Set the PMIC mask for XMEGA.
Input       : R24 - The last 3 bit mask for the PMIC.
Output      : None.
Return      : None.
******************************************************************************/
RMP_Int_Mask:
    LDI                 R30,lo8(RMP_PMIC_CTRL)
    LDI                 R31,hi8(RMP_PMIC_CTRL)
    LD                  R18,Z
    ANDI                R18,0xF8
    OR                  R18,R24
    ST                  Z,R18
    RET
/* End Function:RMP_Int_Enable ***********************************************/

/* Function:_RMP_Start ********************************************************
Description : Jump to the user function and will never return from it.
Input       : [R25:R24] - The entry of the first task.
              [R23:R22] - The stack of the first task.
Output      : None.
Return      : None.
******************************************************************************/
_RMP_Start:
    /* Save the current kernel SP address */
    LDI                 R30,hi8(_RMP_AVR_SP_Kern)
    LDI                 R31,lo8(_RMP_AVR_SP_Kern)
    IN                  R18,RMP_SPL
    IN                  R19,RMP_SPH
    ST                  Z,R18
    STD                 Z+1,R19
    /* Load SP for the first task */
    OUT                 RMP_SPL,R22
    OUT                 RMP_SPH,R23
    /* Jump to the entry */
    MOV                 R30,R24
    MOV                 R31,R25
    ICALL
    /* Should not reach here */
/* End Function:_RMP_Start ***************************************************/

/* Function:_RMP_Yield ********************************************************
Description : Trigger a yield to another thread.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
/* Save all GP regs **********************************************************/
    /* AVR is special in the sense that the CALL and interrupt entry perform
     * exactly the same pushing behavior, hence we can omit the PC push/skip
     * altogether. The interrupt entry-exit behavior is also interesting: the
     * MEGA disables interrupt upon entry and enables it upon RETI, while the
     * XMEGA uses a more modern interrupt prioritization scheme where the global
     * interrupt stays enabled and the PMIC tracks the interrupt status. The 
     * interrupt is not disabled upon entry, and is not enabled upon RETI;
     * The RETI will restore PMIC state in addition to the RET behavior.
     * Hence, for MEGA, we use CLI/RETI pair, while for XMEGA we leverage
     * its PMIC masking features, and we assume all kernel-aware interrupts
     * are low-level interrupts in XMEGA. */
    .macro              RMP_AVR_SAVE
    /* R31-R29 are handled elsewhere because we need some temporaries */
    PUSH                R28
    PUSH                R27
    PUSH                R26
    PUSH                R25
    PUSH                R24
    PUSH                R23
    PUSH                R22
    PUSH                R21
    PUSH                R20
    PUSH                R19
    PUSH                R18
    PUSH                R17
    PUSH                R16
    PUSH                R15
    PUSH                R14
    PUSH                R13
    PUSH                R12
    PUSH                R11
    PUSH                R10
    PUSH                R9
    PUSH                R8
    PUSH                R7
    PUSH                R6
    PUSH                R5
    PUSH                R4
    PUSH                R3
    PUSH                R2
    PUSH                R1
    PUSH                R0
    .endm

/* Actual context switch *****************************************************/
    .macro              RMP_AVR_SWITCH
    IN                  R18,RMP_SPL                 /* Save the SP to control block */
    IN                  R19,RMP_SPH
    LDI                 R28,lo8(RMP_SP_Cur)         /* Y[29:28] is Callee-save */
    LDI                 R29,hi8(RMP_SP_Cur)
    ST                  Y,R18
    STD                 Y+1,R19
    LDI                 R30,lo8(_RMP_AVR_SP_Kern)   /* Load SP for kernel  */
    LDI                 R31,hi8(_RMP_AVR_SP_Kern)
    LD                  R18,Z
    LDD                 R19,Z+1
    OUT                 RMP_SPL,R18
    OUT                 RMP_SPH,R19
    LDI                 R30,lo8(_RMP_Run_High)      /* Get the highest ready task */
    LDI                 R31,hi8(_RMP_Run_High)
    ICALL                                           /* Use ICALL to remain compatible */
    LD                  R18,Y                       /* Load the SP from control block */
    LDD                 R19,Y+1                     /* Y[29:28] is Callee-save */
    OUT                 RMP_SPL,R18
    OUT                 RMP_SPH,R19
    .endm

/* Restore all GP regs *******************************************************/
    .macro              RMP_AVR_LOAD
    POP                 R0
    POP                 R1
    POP                 R2
    POP                 R3
    POP                 R4
    POP                 R5
    POP                 R6
    POP                 R7
    POP                 R8
    POP                 R9
    POP                 R10
    POP                 R11
    POP                 R12
    POP                 R13
    POP                 R14
    POP                 R15
    POP                 R16
    POP                 R17
    POP                 R18
    POP                 R19
    POP                 R20
    POP                 R21
    POP                 R22
    POP                 R23
    POP                 R24
    POP                 R25
    POP                 R26
    POP                 R27
    POP                 R28
    .endm

/* Save temporaries **********************************************************/
    .macro              RMP_AVR_TEMP_SAVE
    /* Push temporaries */
    PUSH                R31
    PUSH                R30
    PUSH                R29
    /* Save SR early */
    IN                  R29,RMP_SREG
    PUSH                R29
    .endm

/* Restore temporaries *******************************************************/
    .macro              RMP_AVR_TEMP_LOAD
    /* Load SR late */
    POP                 R18
    OUT                 RMP_SREG,R18
    /* Pop temporaries */
    POP                 R29
    POP                 R30
    POP                 R31
    .endm

/* Save all RAMPs ************************************************************/
    .macro              RMP_AVR_RAMP_SAVE
    IN                  R21,RMP_RAMPZ
    IN                  R20,RMP_RAMPY
    IN                  R19,RMP_RAMPX
    IN                  R18,RMP_RAMPD
    PUSH                R21
    PUSH                R20
    PUSH                R19
    PUSH                R18
    LDI                 R18,0x00
    OUT                 RMP_RAMPD,R18
    OUT                 RMP_RAMPX,R18
    OUT                 RMP_RAMPY,R18
    OUT                 RMP_RAMPZ,R18
    .endm

/* Restore all RAMPs *********************************************************/
    .macro              RMP_AVR_RAMP_LOAD
    POP                 R18
    POP                 R19
    POP                 R20
    POP                 R21
    OUT                 RMP_RAMPD,R18
    OUT                 RMP_RAMPX,R19
    OUT                 RMP_RAMPY,R20
    OUT                 RMP_RAMPZ,R21
    .endm

/* Save EIND *****************************************************************/
    .macro              RMP_AVR_EIND_SAVE
    IN                  R18,RMP_EIND
    PUSH                R18
    LDI                 R18,0x00
    OUT                 RMP_EIND,R18
    .endm

/* Restore EIND **************************************************************/
    .macro              RMP_AVR_EIND_LOAD
    POP                 R18
    OUT                 RMP_EIND,R18
    .endm

/* Mask interrupts ***********************************************************/
    .macro              RMP_AVR_INT_MASK
    /* Mask all low-level interrupts */
    LDI                 R30,lo8(RMP_PMIC_CTRL)
    LDI                 R31,hi8(RMP_PMIC_CTRL)
    LD                  R29,Z
    ANDI                R29,0xFE
    ST                  Z,R29
    .endm

/* Unmask interrupts *********************************************************/
    .macro              RMP_AVR_INT_UNMASK
    /* Unmask all low-level interrupts */
    LDI                 R30,hi8(RMP_PMIC_CTRL)
    LDI                 R31,lo8(RMP_PMIC_CTRL)
    LD                  R29,Z
    ORI                 R29,0x01
    ST                  Z,R29
    .endm

/* MegaAVR *******************************************************************/
    .section            .text._rmp_avr_yield_mega
    .align              2
_RMP_AVR_Yield_MEGA:
    CLI
    RMP_AVR_TEMP_SAVE
    RMP_AVR_SAVE
    RMP_AVR_SWITCH
    RMP_AVR_LOAD
    RMP_AVR_TEMP_LOAD
    RETI

/* MegaAVR with RAMP *********************************************************/
    .section            .text._rmp_avr_yield_mega_ramp
    .align              2
_RMP_AVR_Yield_MEGA_RAMP:
    CLI
    RMP_AVR_TEMP_SAVE
    RMP_AVR_SAVE
    RMP_AVR_RAMP_SAVE
    RMP_AVR_SWITCH
    RMP_AVR_RAMP_LOAD
    RMP_AVR_LOAD
    RMP_AVR_TEMP_LOAD
    RETI

/* MegaAVR with RAMP and EIND ************************************************/
    .section            .text._rmp_avr_yield_mega_eind
    .align              2
_RMP_AVR_Yield_MEGA_EIND:
    CLI
    RMP_AVR_TEMP_SAVE
    RMP_AVR_SAVE
    RMP_AVR_RAMP_SAVE
    RMP_AVR_EIND_SAVE
    RMP_AVR_SWITCH
    RMP_AVR_EIND_LOAD
    RMP_AVR_RAMP_LOAD
    RMP_AVR_LOAD
    RMP_AVR_TEMP_LOAD
    RETI
    
/* XMegaAVR ******************************************************************/
    .section            .text._rmp_avr_yield_xmega
    .align              2
_RMP_AVR_Yield_XMEGA:
    RMP_AVR_TEMP_SAVE
    RMP_AVR_INT_MASK
    RMP_AVR_SAVE
    RMP_AVR_SWITCH
    RMP_AVR_LOAD
    RMP_AVR_INT_UNMASK
    RMP_AVR_TEMP_LOAD
    /* Use RET instead because we don't want to mess with PMIC */
    RET

/* XMegaAVR with RAMP ********************************************************/
    .section            .text._rmp_avr_yield_xmega_ramp
    .align              2
_RMP_AVR_Yield_XMEGA_RAMP:
    RMP_AVR_TEMP_SAVE
    RMP_AVR_INT_MASK
    RMP_AVR_SAVE
    RMP_AVR_RAMP_SAVE
    RMP_AVR_SWITCH
    RMP_AVR_RAMP_LOAD
    RMP_AVR_LOAD
    RMP_AVR_INT_UNMASK
    RMP_AVR_TEMP_LOAD
    /* Use RET instead because we don't want to mess with PMIC */
    RET

/* XMegaAVR with RAMP and EIND ***********************************************/
    .section            .text._rmp_avr_yield_xmega_eind
    .align              2
_RMP_AVR_Yield_XMEGA_EIND:
    RMP_AVR_TEMP_SAVE
    RMP_AVR_INT_MASK
    RMP_AVR_SAVE
    RMP_AVR_RAMP_SAVE
    RMP_AVR_EIND_SAVE
    RMP_AVR_SWITCH
    RMP_AVR_EIND_LOAD
    RMP_AVR_RAMP_LOAD
    RMP_AVR_LOAD
    RMP_AVR_INT_UNMASK
    RMP_AVR_TEMP_LOAD
    /* Use RET instead because we don't want to mess with PMIC */
    RET
/* End Function:_RMP_Yield ***************************************************/
    .end
/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/