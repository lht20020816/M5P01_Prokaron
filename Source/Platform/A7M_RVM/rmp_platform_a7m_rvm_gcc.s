/******************************************************************************
Filename    : rmp_platform_cmx_rvm_asm.S
Author      : pry
Date        : 09/02/2018
Description : The assembly part of the RMP RTOS for the RVM virtual machine monitor.
              This is for use with gcc.
******************************************************************************/

/* The ARM Cortex-M Architecture **********************************************
R0-R7:General purpose registers that are accessible. 
R8-R12:General purpose registers that can only be reached by 32-bit instructions.
R13:SP/SP_process/SP_main    Stack pointer
R14:LR                       Link Register(used for returning from a subfunction)
R15:PC                       Program counter.
IPSR                         Interrupt Program Status Register.
APSR                         Application Program Status Register.
EPSR                         Execute Program Status Register.
The above 3 registers are saved into the stack in combination(xPSR).
The ARM Cortex-M4/7 also include a FPU.
******************************************************************************/

/* Begin Header **************************************************************/
    .syntax             unified
    .thumb
    .section            ".text"
    .align              3
/* End Header ****************************************************************/

/* Begin Exports *************************************************************/
    /* Start the first thread */
    .global             _RMP_Start
    /* Get the MSB/LSB in the word */
    .global             _RMP_A7M_RVM_MSB_Get
    .global             _RMP_A7M_RVM_LSB_Get
    /* Fast-path context switching without invoking the RVM */
    .global             _RMP_A7M_RVM_Yield
/* End Exports ***************************************************************/

/* Begin Imports ************************************************************/
    /* The real task switch handling function */
    .global             _RMP_Run_High
    /* The stack address of current thread */
    .global             RMP_SP_Cur
    /* Save and load extra contexts, such as FPU, peripherals and MPU */
    .global             RMP_Ctx_Save
    .global             RMP_Ctx_Load
    /* Mask/unmask interrupts */
    .global             RMP_Int_Mask
    .global             RMP_Int_Unmask
    /* Hypercall parameter space */
    .global             RMP_A7M_RVM_Usr_Param
/* End Imports **************************************************************/

/* Begin Function:_RMP_Start **************************************************
Description : Jump to the user function and will never return from it.
Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
    .thumb_func
_RMP_Start:
    SUB                 R1,#16              /* This is how we push our registers so move forward */
    MOV                 SP,R1               /* Set the stack pointer */
                
    ISB                                     /* Instruction barrier */
    BLX                 R0                  /* Branch to our target */
/* End Function:_RMP_Start ***************************************************/

/* Begin Function:_RMP_A7M_RVM_MSB_Get ****************************************
Description : Get the MSB of the word.
Input       : rmp_ptr_t Val - The value.
Output      : None.
Return      : rmp_ptr_t - The MSB position.
******************************************************************************/
    .thumb_func
_RMP_A7M_RVM_MSB_Get:
    CLZ                 R1,R0
    MOV                 R0,#31
    SUB                 R0,R1
    BX                  LR
/* End Function:_RMP_A7M_RVM_MSB_Get *****************************************/

/* Begin Function:_RMP_A7M_RVM_LSB_Get ****************************************
Description : Get the LSB of the word.
Input       : rmp_ptr_t Val - The value.
Output      : None.
Return      : rmp_ptr_t - The LSB position.
******************************************************************************/
    .thumb_func
_RMP_A7M_RVM_LSB_Get:
    RBIT                R0,R0
    CLZ                 R0,R0
    BX                  LR
/* End Function:_RMP_A7M_RVM_LSB_Get *****************************************/

/* Begin Function:_RMP_A7M_RVM_Yield ******************************************
Description : Switch from user code to another thread, rather than from the 
              interrupt handler. Need to masquerade the context well so that
              it may be recovered from the interrupt handler as well.
              Caveats: 
              1. User-level code cannot clear CONTROL.FPCA hence all threads
                 in the system will be tainted with the FPU flag and include
                 a full context save/restore. Yet this is still much faster
                 than the traditional slow path through the PendSV.
              2. After the user have stacked up everything on its stack but
                 not disabled its interrupt yet, an interrupt may occur, and
                 stack again on the user stack. This is allowed, but must be
                 taken into account when calculating stack usage.

              The exception extended stack layout is as follows:

               Unaligned           Aligned
               Reserved           
               Reserved            Reserved
               FPSCR               FPSCR
               S15                 S15
               S14                 S14
               S13                 S13
               S12                 S12
               S11                 S11
               S10                 S10
               S9                  S9
               S8                  S8
               S7                  S7
               S6                  S6
               S5                  S5
               S4                  S4
               S3                  S3
               S2                  S2
               S1                  S1
               S0                  S0
               XPSR                XPSR
               PC                  PC
               LR                  LR
               R12                 R12
               R3                  R3
               R2                  R2
               R1                  R1
               R0                  R0

Input       : None.
Output      : None.
Return      : None.
******************************************************************************/
/* Exception Entry Stacking **************************************************/
.macro THUMB FUNC
	.thumb_func
    \FUNC
.endm
    /* Alignment detection */
    .macro              ALIGN_PUSH, LABEL
    MOV                 R0,SP
    TST                 R0,#0x00000007
    BNE                 \LABEL
    .endm

    /* Exception stacking for basic frame */
    .macro EXC_PUSH, SZ, XPSR, LR  
    LDR                 R0, [SP, #4]  
    SUB                 SP, #4*(\SZ-8)  
    PUSH                {R0-R3, R12, LR}  
    LDR                 R0, [SP, #4*(\SZ-2)]  
    LDR                 R1, =\XPSR  
    ORR                 R0, R1  
    STR                 R0, [SP, #4*7]  
    LDR                 R0, =_RMP_A7M_Skip  
    AND                 R0, #0xFFFFFFFE  
    STR                 R0, [SP, #4*6]  
    MOV                 LR, #\LR  
    .endm

/* Exception Exit Unstacking *************************************************/
    /* Alignment detection */
    .macro              ALIGN_POP, LABEL  
    LDR                 R0, [SP, #4*7]  
    TST                 R0, #0x00000200  
    BNE                 \LABEL  
    .endm

    // Exception unstacking for basic frame:
    // The original consists of [PAD] [FPU] XPSR PC LR R12 R3-R0. 
    // This is not very ideal for restoring the context without
    // touching the XPSR, which is susceptible to changes.
    // PC R0 XPSR Temp .... is far more ideal. This snippet does 
    // the manipulations accordingly. It
    // (1) transforms the stack into         PC XPSR LR ... R0
    // (2) pops off GP regs and result in    PC XPSR
    // (3) makes more space on stack         PC XPSR ---- Temp
    // (4) stores R0 to temp                 PC XPSR ---- R0
    // (5) moves XPSR to back                PC ---- XPSR R0
    // (6) moves R0 to front                 PC R0   XPSR ----
    // (7) restores xpsr through R0          PC R0
    // (8) restores R0 and PC                PC R0
    // Note that in the transformation we never place variables 
    // at lower addresses than the current SP, as this will run 
    // the risk of a racing interrupt erasing the variable.
    .macro              EXC_POP, SZ  
    LDR                 R1, [SP, #4*6]  
    ORR                 R1, #0x00000001  
    STR                 R1, [SP, #4*(\SZ-1)]  
    AND                 R0, #0xFFFFFDFF  
    STR                 R0, [SP, #4*(\SZ-2)]  
    POP                 {R0-R3, R12, LR}  
    ADD                 SP, #4*(\SZ-10)  
    STR                 R0, [SP]  
    LDR                 R0, [SP, #4*2]  
    STR                 R0, [SP, #4*1]  
    LDR                 R0, [SP]  
    STR                 R0, [SP, #4*2]  
    ADD                 SP, #4  
    POP                 {R0}  
    MSR                 XPSR, R0  
    POP                 {R0}  
    POP                 {PC}  
    .endm

/* User-level Context Switch *************************************************/
THUMB _RMP_A7M_RVM_Yield:
    PUSH                {R0}                // Protect R0 and XPSR
    MRS                 R0, XPSR
    PUSH                {R0}
    MRS                 R0, CONTROL
    TST                 R0, #0x00000004     // CONTROL.FPCA
    BNE                 Stk_Extend

THUMB Stk_Basic:
    ALIGN_PUSH          Stk_Basic_Unalign
THUMB Stk_Basic_Align:
    EXC_PUSH            8, 0x01000000, 0xFFFFFFFD
    B                   Stk_Basic_Done
THUMB Stk_Basic_Unalign:
    EXC_PUSH            8+1, 0x01000200, 0xFFFFFFFD
    B                   Stk_Basic_Done
    
THUMB Stk_Extend:
    ALIGN_PUSH          Stk_Extend_Unalign
THUMB Stk_Extend_Align:
    EXC_PUSH            8+17+1, 0x01000000, 0xFFFFFFED
    B                   Stk_Extend_Done
THUMB Stk_Extend_Unalign:
    EXC_PUSH            8+17+2, 0x01000200, 0xFFFFFFED
THUMB Stk_Extend_Done:
    ADD                 R0, SP, #4*8        // Locate FPU stacking area
    .short              0xECA0              // Push FPU regs
    .short              0x0A10              // VSTMIA R0!, {S0-S15}
    .short              0xEEF1              // Push FPSCR
    .short              0x1A10              // VMRS R1, FPSCR
    STR                 R1, [R0]
    .short              0xED2D              // Push OS-managed FPU regs
    .short              0x8A10              // VPUSH {S16-S31}   

THUMB Stk_Basic_Done:       
    PUSH                {R4-R11, LR}        // Push GP regs
    LDR                 R0, =RMP_A7M_RVM_Usr_Param
    LDR                 R0, [R0]            // Push hypercall parameters
    LDMIA               R0, {R1-R5}
    PUSH                {R1-R5}

    BL                  RMP_Int_Mask        // Mask interrupts
    BL                  RMP_Ctx_Save        // Save extra context

    LDR                 R1, =RMP_SP_Cur     // Save the SP to control block.
    STR                 SP, [R1]

    BL                  _RMP_Run_High       // Get the highest ready task.

    LDR                 R1, =RMP_SP_Cur     // Load the SP.
    LDR                 SP, [R1]

    BL                  RMP_Ctx_Load        // Load extra context
    BL                  RMP_Int_Unmask      // Unmask interrupts

    LDR                 R0, =RMP_A7M_RVM_Usr_Param
    LDR                 R0, [R0]            // Pop hypercall parameters
    POP                 {R1-R5}
    STMIA               R0, {R1-R5}
    POP                 {R4-R11, LR}        // Pop GP regs

    // Read LR and decide whether to restore FPU context.
    TST                 LR, #0x00000010     // LR.EXTENDED
    BEQ                 Uns_Extend

THUMB Uns_Basic:
    ALIGN_POP           Uns_Basic_Unalign
THUMB Uns_Basic_Align:
    EXC_POP             8
THUMB Uns_Basic_Unalign:
    EXC_POP             8+1

THUMB Uns_Extend:
    .short              0xECBD              // Pop OS-managed FPU regs
    .short              0x8A10              // VPOP {S16-S31}           
    ADD                 R0, SP, #4*(8+16)
    LDR                 R1, [R0]
    .short              0xEEE1              // Pop FPSCR
    .short              0x1A10              // VMSR FPSCR, R1
    .short              0xED30              // Pop FPU regs
    .short              0x0A10              // VLDMDB R0!, {S0-S15}
    // Extended frame
    ALIGN_POP           Uns_Extend_Unalign
THUMB Uns_Extend_Align:
    EXC_POP             8+17+1
THUMB Uns_Extend_Unalign:
    EXC_POP             8+17+2

THUMB _RMP_A7M_Skip:
    BX                  LR

/* End Function:_RMP_A7M_RVM_Yield *******************************************/

    .end
/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/

