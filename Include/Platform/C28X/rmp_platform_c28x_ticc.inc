;/*****************************************************************************
;Filename    : rmp_platform_c28x_ticc.inc
;Author      : zr (ran zhang)
;Date        : 27/04/2024
;Description : The assembly part of the RMP RTOS. This is for C28X, and
;              contains macros to be included in all interrupt assembly code
;              as needed.
;*****************************************************************************/

;/* Import *******************************************************************/
    ;Make things compatible for both COFF and EABI
    .if __TI_EABI__
    .asg                    _RMP_C28X_SP_Kern,__RMP_C28X_SP_Kern
    .asg                    RMP_SP_Cur,_RMP_SP_Cur
    .asg                    RMP_C28X_Int_Act,_RMP_C28X_Int_Act
    .asg                    _RMP_C28X_Yield_Pend,__RMP_C28X_Yield_Pend
    .asg                    _RMP_Run_High,__RMP_Run_High
    .asg                    _RMP_C28X_Tim_Handler,__RMP_C28X_Tim_Handler
    .endif

    ;The kernel stack
    .global                 __RMP_C28X_SP_Kern
    ;The current thread stack
    .global                 _RMP_SP_Cur
    ;The interrupt active flag
    .global                 _RMP_C28X_Int_Act
    ;The yield pending flag
    .global                 __RMP_C28X_Yield_Pend
    ;Extract highest priority running thread
    .global                 __RMP_Run_High
    ;Handler for C28X timer interrupt
    .global                 __RMP_C28X_Tim_Handler
;/* End Import ***************************************************************/

;/* Macro ********************************************************************/
;/* Save all GP regs *********************************************************/
RMP_C28X_SAVE               .macro
    PUSH                    RPC
    PUSH                    AR1H:AR0H
    PUSH                    XAR2
    PUSH                    XAR3
    PUSH                    XAR4
    PUSH                    XAR5
    PUSH                    XAR6
    PUSH                    XAR7
    PUSH                    XT
    .endm

;/* Prepare for a context switch *********************************************/
RMP_C28X_SWITCH_PRE         .macro
    MOV                     AL,SP
    MOV                     DP,#_RMP_SP_Cur
    MOV                     @_RMP_SP_Cur,AL
    MOV                     DP,#__RMP_C28X_SP_Kern
    MOV                     AL,@__RMP_C28X_SP_Kern
    MOV                     SP,AL
    MOV                     AL,#1
    MOV                     DP,#_RMP_C28X_Int_Act
    MOV                     @_RMP_C28X_Int_Act,AL
    .endm

;/* Finish up the context switch **********************************************/
RMP_C28X_SWITCH_POST        .macro
    MOV                     DP,#__RMP_C28X_Yield_Pend
    MOV                     AL,@__RMP_C28X_Yield_Pend
    SBF                     RMP_C28X_YIELD_SKIP?,EQ
    MOV                     AL,#0
    MOV                     @__RMP_C28X_Yield_Pend, AL
    LCR                     __RMP_Run_High
RMP_C28X_YIELD_SKIP?
    MOV                     AL,#0
    MOV                     DP,#_RMP_C28X_Int_Act
    MOV                     @_RMP_C28X_Int_Act,AL
    MOV                     DP,#_RMP_SP_Cur
    MOV                     AL,@_RMP_SP_Cur
    MOV                     SP,AL
    .endm

;/* Restore all GP regs ******************************************************/
RMP_C28X_RESTORE            .macro
    POP                     XT
    POP                     XAR7
    POP                     XAR6
    POP                     XAR5
    POP                     XAR4
    POP                     XAR3
    POP                     XAR2
    POP                     AR1H:AR0H
    POP                     RPC
    ;Return from interrupt
    IRET
    .endm

;/* Save macro for no coprocessor case ***************************************/
RMP_C28X_INT_SAVE_NONE      .macro
    RMP_C28X_SAVE
    RMP_C28X_SWITCH_PRE
    .endm

;/* Load macro for no coprocessor case ***************************************/
RMP_C28X_INT_RESTORE_NONE   .macro
    RMP_C28X_SWITCH_POST
    RMP_C28X_RESTORE
    .endm

;/* Save macro for FPU32 case ************************************************/
RMP_C28X_INT_SAVE_FPU32     .macro
    RMP_C28X_SAVE
    ;Push FPU registers
    .word                   0xE200      ;MOV32   *SP++, STF
    .word                   0x00BD
    .word                   0xFFF0      ;PUSH    RB
    .word                   0xE203      ;MOV32   *SP++, R0H
    .word                   0x00BD
    .word                   0xE203      ;MOV32   *SP++, R1H
    .word                   0x01BD
    .word                   0xE203      ;MOV32   *SP++, R2H
    .word                   0x02BD
    .word                   0xE203      ;MOV32   *SP++, R3H
    .word                   0x03BD
    .word                   0xE203      ;MOV32   *SP++, R4H
    .word                   0x04BD
    .word                   0xE203      ;MOV32   *SP++, R5H
    .word                   0x05BD
    .word                   0xE203      ;MOV32   *SP++, R6H
    .word                   0x06BD
    .word                   0xE203      ;MOV32   *SP++, R7H
    .word                   0x07BD
    RMP_C28X_SWITCH_PRE
    .endm

;/* Load macro for FPU32 case ************************************************/
RMP_C28X_INT_RESTORE_FPU32  .macro
    RMP_C28X_SWITCH_POST
    ;Pop FPU registers
    .word                   0xE2AF      ;MOV32   R7H,*--SP
    .word                   0x07BE
    .word                   0xE2AF      ;MOV32   R6H,*--SP
    .word                   0x06BE
    .word                   0xE2AF      ;MOV32   R5H,*--SP
    .word                   0x05BE
    .word                   0xE2AF      ;MOV32   R4H,*--SP
    .word                   0x04BE
    .word                   0xE2AF      ;MOV32   R3H,*--SP
    .word                   0x03BE
    .word                   0xE2AF      ;MOV32   R2H,*--SP
    .word                   0x02BE
    .word                   0xE2AF      ;MOV32   R1H,*--SP
    .word                   0x01BE
    .word                   0xE2AF      ;MOV32   R0H,*--SP
    .word                   0x00BE
    .word                   0xFFF1      ;POP     RB
    .word                   0xE280      ;MOV32   STF,*--SP
    .word                   0x00BE
    RMP_C28X_RESTORE
    .endm

;/* Save macro for FPU64 case ************************************************/
RMP_C28X_INT_SAVE_FPU64     .macro
    RMP_C28X_SAVE
    ;Push FPU registers
    .word                   0xE200      ;MOV32   *SP++, STF
    .word                   0x00BD
    .word                   0xFFF0      ;PUSH    RB
    .word                   0xE202      ;MOV32   *SP++, R0L
    .word                   0x00BD
    .word                   0xE203      ;MOV32   *SP++, R0H
    .word                   0x00BD
    .word                   0xE202      ;MOV32   *SP++, R1L
    .word                   0x01BD
    .word                   0xE203      ;MOV32   *SP++, R1H
    .word                   0x01BD
    .word                   0xE202      ;MOV32   *SP++, R2L
    .word                   0x02BD
    .word                   0xE203      ;MOV32   *SP++, R2H
    .word                   0x02BD
    .word                   0xE202      ;MOV32   *SP++, R3L
    .word                   0x03BD
    .word                   0xE203      ;MOV32   *SP++, R3H
    .word                   0x03BD
    .word                   0xE202      ;MOV32   *SP++, R4L
    .word                   0x04BD
    .word                   0xE203      ;MOV32   *SP++, R4H
    .word                   0x04BD
    .word                   0xE202      ;MOV32   *SP++, R5L
    .word                   0x05BD
    .word                   0xE203      ;MOV32   *SP++, R5H
    .word                   0x05BD
    .word                   0xE202      ;MOV32   *SP++, R6L
    .word                   0x06BD
    .word                   0xE203      ;MOV32   *SP++, R6H
    .word                   0x06BD
    .word                   0xE202      ;MOV32   *SP++, R7L
    .word                   0x07BD
    .word                   0xE203      ;MOV32   *SP++, R7H
    .word                   0x07BD
    RMP_C28X_SWITCH_PRE
    .endm

;/* Load macro for FPU64 case ************************************************/
RMP_C28X_INT_RESTORE_FPU64  .macro
    RMP_C28X_SWITCH_POST
    ;Pop FPU registers
    .word                   0xE2AF      ;MOV32   R7H,*--SP
    .word                   0x07BE
    .word                   0xE29F      ;MOV32   R7L,*--SP
    .word                   0x07BE
    .word                   0xE2AF      ;MOV32   R6H,*--SP
    .word                   0x06BE
    .word                   0xE29F      ;MOV32   R6L,*--SP
    .word                   0x06BE
    .word                   0xE2AF      ;MOV32   R5H,*--SP
    .word                   0x05BE
    .word                   0xE29F      ;MOV32   R5L,*--SP
    .word                   0x05BE
    .word                   0xE2AF      ;MOV32   R4H,*--SP
    .word                   0x04BE
    .word                   0xE29F      ;MOV32   R4L,*--SP
    .word                   0x04BE
    .word                   0xE2AF      ;MOV32   R3H,*--SP
    .word                   0x03BE
    .word                   0xE29F      ;MOV32   R3L,*--SP
    .word                   0x03BE
    .word                   0xE2AF      ;MOV32   R2H,*--SP
    .word                   0x02BE
    .word                   0xE29F      ;MOV32   R2L,*--SP
    .word                   0x02BE
    .word                   0xE2AF      ;MOV32   R1H,*--SP
    .word                   0x01BE
    .word                   0xE29F      ;MOV32   R1L,*--SP
    .word                   0x01BE
    .word                   0xE2AF      ;MOV32   R0H,*--SP
    .word                   0x00BE
    .word                   0xE29F      ;MOV32   R0L,*--SP
    .word                   0x00BE
    .word                   0xFFF1      ;POP     RB
    .word                   0xE280      ;MOV32   STF,*--SP
    .word                   0x00BE
    RMP_C28X_RESTORE
    .endm
;/* End Macro ****************************************************************/

;/* End Of File **************************************************************/

;/* Copyright (C) Evo-Devo Instrum. All rights reserved **********************/