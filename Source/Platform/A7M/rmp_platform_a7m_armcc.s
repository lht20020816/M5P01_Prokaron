;/*****************************************************************************
;Filename    : rmp_platform_a7m_armcc.s
;Author      : pry
;Date        : 10/04/2012
;Description : The assembly part of the RMP RTOS. This is for ARMv7-M.
;*****************************************************************************/

;/* The ARMv7-M Architecture **************************************************
;R0-R7:General purpose registers that are accessible. 
;R8-R12:General purpose registers that can only be reached by 32-bit instructions.
;R13:SP/SP_process/SP_main    Stack pointer
;R14:LR                       Link Register(used for returning from a subfunction)
;R15:PC                       Program counter.
;IPSR                         Interrupt Program Status Register.
;APSR                         Application Program Status Register.
;EPSR                         Execute Program Status Register.
;The above 3 registers are saved into the stack in combination(xPSR).
;
;The ARM Cortex-M4/7 also include a FPU.
;*****************************************************************************/
            
;/* Begin Header *************************************************************/
                        ;2^3=8 byte alignment.
                        AREA                ARCH, CODE, READONLY, ALIGN=3                     
                                    
                        THUMB
                        REQUIRE8
                        PRESERVE8
;/* End Header ***************************************************************/

;/* Begin Exports ************************************************************/
                        ; Disable all interrupts
                        EXPORT              RMP_Int_Disable      
                        ; Enable all interrupts            
                        EXPORT              RMP_Int_Enable
                        ; Mask/unmask some interrupts
                        EXPORT              RMP_Int_Mask
                        ; Get the MSB                              
                        EXPORT              RMP_MSB_Get
                        ; Start the first thread
                        EXPORT              _RMP_Start
                        ; The PendSV trigger
                        EXPORT              _RMP_Yield
                        ; The system pending service routine              
                        EXPORT              PendSV_Handler 
                        ; The systick timer routine              
                        EXPORT              SysTick_Handler                               
;/* End Exports **************************************************************/

;/* Begin Imports ************************************************************/
                        ; The real task switch handling function
                        IMPORT              _RMP_Run_High 
                        ; The real systick handler function
                        IMPORT              _RMP_Tim_Handler
                        ; The PID of the current thread                     
                        IMPORT              RMP_Thd_Cur
                        ; The stack address of current thread
                        IMPORT              RMP_SP_Cur        
                        ; Save and load extra contexts, such as FPU, peripherals and MPU
                        IMPORT              RMP_Ctx_Save
                        IMPORT              RMP_Ctx_Load
;/* End Imports **************************************************************/

;/* Begin Function:RMP_Int_Disable ********************************************
;Description : The function for disabling all interrupts. Does not allow nesting.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/    
RMP_Int_Disable         PROC
                        CPSID               I
                        BX                  LR
                        ENDP
;/* End Function:RMP_Int_Disable *********************************************/

;/* Begin Function:RMP_Int_Enable *********************************************
;Description : The function for enabling all interrupts. Does not allow nesting.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
RMP_Int_Enable          PROC
                        CPSIE               I
                        BX                  LR
                        ENDP
;/* End Function:RMP_Int_Enable **********************************************/

;/* Begin Function:RMP_Int_Mask ***********************************************
;Description : The function for masking & unmasking interrupts. Does not allow nesting.
;Input       : rmp_ptr_t R0 - The new BASEPRI to set.
;Output      : None.
;Return      : None.
;*****************************************************************************/
RMP_Int_Mask            PROC
                        MSR                 BASEPRI, R0
                        ; We are not influenced by errata #837070 as the next 
                        ; instruction is BX LR. Thus we have a free window.
                        BX                  LR
                        ENDP
;/* End Function:RMP_Int_Mask ************************************************/

;/* Begin Function:RMP_MSB_Get ************************************************
;Description : Get the MSB of the word.
;Input       : rmp_ptr_t R0 - The value.
;Output      : None.
;Return      : rmp_ptr_t R0 - The MSB position.
;*****************************************************************************/
RMP_MSB_Get             PROC
                        CLZ                 R1, R0
                        MOVS                R0, #31
                        SUBS                R0, R1
                        BX                  LR
                        ENDP
;/* End Function:RMP_MSB_Get *************************************************/

;/* Begin Function:_RMP_Yield *************************************************
;Description : Trigger a yield to another thread.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
_RMP_Yield              PROC
                        LDR                 R0, =0xE000ED04      ;The NVIC_INT_CTRL register
                        LDR                 R1, =0x10000000      ;Trigger the PendSV          
                        STR                 R1, [R0]
                        ISB
                        BX                  LR
                        ENDP
;/* End Function:_RMP_Yield **************************************************/

;/* Begin Function:_RMP_Start *************************************************
;Description : Jump to the user function and will never return from it.
;Input       : None.
;Output      : None.
;Return      : None.                                   
;*****************************************************************************/
_RMP_Start              PROC
                        SUBS                R1, #64             ;This is how we push our registers so move forward
                        MSR                 PSP, R1             ;Set the stack pointer
                        MOVS                R4, #0x02           ;Previleged thread mode
                        MSR                 CONTROL, R4
                        ISB
                        BX                  R0                  ;Branch to our target
                        ENDP
;/* End Function:_RMP_Start **************************************************/

;/* Begin Function:PendSV_Handler *********************************************
;Description : The PendSV interrupt routine. In fact, it will call a C function
;              directly. The reason why the interrupt routine must be an assembly
;              function is that the compiler may deal with the stack in a different 
;              way when different optimization level is chosen. An assembly function
;              can make way around this problem.
;              However, if your compiler support inline assembly functions, this
;              can also be written in C.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
PendSV_Handler          PROC
                        MRS                 R0,PSP              ; Save registers
                        TST                 LR,#0x10            ; Save FPU registers
                        DCI                 0xBF08              ; IT EQ ;If yes, (DCI for compatibility with no FPU support)
                        DCI                 0xED20              ; VSTMDBEQ R0!,{S16-S31}
                        DCI                 0x8A10              ; Save FPU registers not saved by lazy stacking.
                        STMDB               R0!,{R4-R11,LR}     ; Save the general purpose registers.
                        
                        BL                  RMP_Ctx_Save        ; Save extra context
                                    
                        LDR                 R1,=RMP_SP_Cur      ; Save The SP to control block.
                        STR                 R0,[R1]
                                    
                        BL                  _RMP_Run_High       ; Get the highest ready task.
                                    
                        LDR                 R1,=RMP_SP_Cur      ; Load the SP.
                        LDR                 R0,[R1]
                                    
                        BL                  RMP_Ctx_Load        ; Load extra context

                        LDMIA               R0!,{R4-R11,LR}     ; Restore registers
                        TST                 LR,#0x10            ; Load FPU registers
                        DCI                 0xBF08              ; IT EQ ;If yes, (DCI for compatibility with no FPU support)
                        DCI                 0xECB0              ; VLDMIAEQ R0!,{S16-S31}
                        DCI                 0x8A10              ; Load FPU registers not loaded by lazy stacking.
                        MSR                 PSP,R0
    
                        ; Some chips such as XMC4xxx step AA/step AB may corrupt on this branch.
                        ; For those chips, you must manually edit this to PUSH {LR} then POP {PC}. 
                        BX                  LR                  ; The LR will indicate whether we are using FPU.
                        ENDP
;/* End Function:PendSV_Handler **********************************************/

;/* Begin Function:SysTick_Handler ********************************************
;Description : The SysTick interrupt routine. In fact, it will call a C function
;              directly. The reason why the interrupt routine must be an assembly
;              function is that the compiler may deal with the stack in a different 
;              way when different optimization level is chosen. An assembly function
;              can make way around this problem.
;              However, if your compiler support inline assembly functions, this
;              can also be written in C.
;Input       : None.
;Output      : None.
;Return      : None.
;*****************************************************************************/
SysTick_Handler         PROC
                        PUSH                {LR}
                                    
                        MOVS                R0,#0x01            ;We are not using tickless.
                        BL                  _RMP_Tim_Handler
                                    
                        POP                 {PC}
                        ENDP
;/* End Function:SysTick_Handler *********************************************/
                        ALIGN
                        END
;/* End Of File **************************************************************/

;/* Copyright (C) Evo-Devo Instrum. All rights reserved **********************/
