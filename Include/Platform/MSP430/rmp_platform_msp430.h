/******************************************************************************
Filename    : rmp_platform_msp430.h
Author      : pry
Date        : 01/04/2017
Licence     : The Unlicense; see LICENSE for details.
Description : The header of "rmp_platform_msp430.c".
******************************************************************************/

/* Defines *******************************************************************/
#ifdef __HDR_DEFS__
#ifndef __RMP_PLATFORM_MSP430_H_DEFS__
#define __RMP_PLATFORM_MSP430_H_DEFS__
/*****************************************************************************/
/* Basic Types ***************************************************************/
#ifndef __RMP_S32_T__
#define __RMP_S32_T__
typedef signed long rmp_s32_t;
#endif

#ifndef __RMP_S16_T__
#define __RMP_S16_T__
typedef signed int rmp_s16_t;
#endif

#ifndef __RMP_S8_T__
#define __RMP_S8_T__
typedef signed char rmp_s8_t;
#endif

#ifndef __RMP_U32_T__
#define __RMP_U32_T__
typedef unsigned long rmp_u32_t;
#endif

#ifndef __RMP_U16_T__
#define __RMP_U16_T__
typedef unsigned int rmp_u16_t;
#endif

#ifndef __RMP_U8_T__
#define __RMP_U8_T__
typedef unsigned char rmp_u8_t;
#endif
/* End Basic Types ***********************************************************/

/* Begin Extended Types ******************************************************/
/* The CPU and application specific macros are here */
#include "rmp_platform_msp430_conf.h"

#ifndef __RMP_PTR_T__
#define __RMP_PTR_T__
/* The typedef for the pointers - This is the raw style. Pointers must be unsigned */
#if(RMP_MSP430_X!=0U)
typedef rmp_u32_t rmp_ptr_t;
#else
typedef rmp_u16_t rmp_ptr_t;
#endif
#endif

#ifndef __RMP_CNT_T__
#define __RMP_CNT_T__
/* The typedef for the count variables */
typedef rmp_s16_t rmp_cnt_t;
#endif

#ifndef __RMP_RET_T__
#define __RMP_RET_T__
/* The type for return value */
#if(RMP_MSP430_X!=0U)
typedef rmp_s32_t rmp_ret_t;
#else
typedef rmp_s16_t rmp_ret_t;
#endif
#endif
/* End Extended Types ********************************************************/

/* System macros *************************************************************/
/* Compiler "extern" keyword setting */
#define EXTERN                          extern
/* The order of bits in one CPU machine word */
#if(RMP_MSP430_X==1U)
#define RMP_WORD_ORDER                  (5U)
#else
#define RMP_WORD_ORDER                  (4U)
#endif
/* The maximum length of char printing - no need to change this in most cases */
#define RMP_DEBUG_PRINT_MAX             (128U)
/* Descending stack, 4-byte alignment */
#define RMP_INIT_STACK                  RMP_INIT_STACK_DESCEND(2U)
/* MSB/LSB extraction */
#define RMP_MSB_GET(VAL)                RMP_MSB_Generic(VAL)
#define RMP_LSB_GET(VAL)                RMP_LSB_Generic(VAL)
/* End System macros *********************************************************/

/* MSP430 specific macros ****************************************************/
#define RMP_MSP430_SR_SCG1              (1<<7)
#define RMP_MSP430_SR_SCG0              (1<<6)
#define RMP_MSP430_SR_OSCOFF            (1<<5)
#define RMP_MSP430_SR_CPUOFF            (1<<4)
#define RMP_MSP430_SR_GIE               (1<<3)

#define RMP_MSP430X_PCSR(PC,SR)         (((PC)<<16)|(((PC)>>4)&0xF000)|(SR))
/*****************************************************************************/
/* __RMP_PLATFORM_MSP430_H_DEFS__ */
#endif
/* __HDR_DEFS__ */
#endif
/* End Defines ***************************************************************/

/* Structs *******************************************************************/
#ifdef __HDR_STRUCTS__
#ifndef __RMP_PLATFORM_MSP430_H_STRUCTS__
#define __RMP_PLATFORM_MSP430_H_STRUCTS__
/* We used structs in the header */

/* Use defines in these headers */
#define __HDR_DEFS__
#undef __HDR_DEFS__
/*****************************************************************************/
#if(RMP_MSP430_X!=0U)
struct RMP_MSP430_Stack
{
    rmp_ptr_t R4;
    rmp_ptr_t R5;
    rmp_ptr_t R6;
    rmp_ptr_t R7;
    rmp_ptr_t R8;
    rmp_ptr_t R9;
    rmp_ptr_t R10;
    rmp_ptr_t R11;
    rmp_ptr_t R12;
    rmp_ptr_t R13;
    rmp_ptr_t R14;
    rmp_ptr_t R15;
    rmp_ptr_t PCSR;
};
#else
struct RMP_MSP430_Stack
{
    rmp_ptr_t R4;
    rmp_ptr_t R5;
    rmp_ptr_t R6;
    rmp_ptr_t R7;
    rmp_ptr_t R8;
    rmp_ptr_t R9;
    rmp_ptr_t R10;
    rmp_ptr_t R11;
    rmp_ptr_t R12;
    rmp_ptr_t R13;
    rmp_ptr_t R14;
    rmp_ptr_t R15;
    rmp_ptr_t SR;
    rmp_ptr_t PC;
};
#endif
/*****************************************************************************/
/* __RMP_PLATFORM_MSP430_H_STRUCTS__ */
#endif
/* __HDR_STRUCTS__ */
#endif
/* End Structs ***************************************************************/

/* Private Global Variables **************************************************/
#if(!(defined __HDR_DEFS__||defined __HDR_STRUCTS__))
#ifndef __RMP_PLATFORM_MSP430_MEMBERS__
#define __RMP_PLATFORM_MSP430_MEMBERS__

/* In this way we can use the data structures and definitions in the headers */
#define __HDR_DEFS__

#undef __HDR_DEFS__

#define __HDR_STRUCTS__

#undef __HDR_STRUCTS__

/* If the header is not used in the public mode */
#ifndef __HDR_PUBLIC_MEMBERS__
/*****************************************************************************/

/*****************************************************************************/
/* End Private Global Variables **********************************************/

/* Private C Function Prototypes *********************************************/ 
/*****************************************************************************/

/*****************************************************************************/
#define __EXTERN__
/* End Private C Function Prototypes *****************************************/

/* Public Global Variables ***************************************************/
/* __HDR_PUBLIC_MEMBERS__ */
#else
#define __EXTERN__ EXTERN 
/* __HDR_PUBLIC_MEMBERS__ */
#endif

/*****************************************************************************/
__EXTERN__ rmp_ptr_t _RMP_MSP430_SP_Kern;

__EXTERN__ volatile rmp_ptr_t RMP_MSP430_Int_Act;
__EXTERN__ volatile rmp_ptr_t _RMP_MSP430_Yield_Pend;
/*****************************************************************************/

/* End Public Global Variables ***********************************************/

/* Public C Function Prototypes **********************************************/
/*****************************************************************************/
/* Interrupts */
EXTERN void RMP_Int_Disable(void);
EXTERN void RMP_Int_Enable(void);

EXTERN void _RMP_Start(rmp_ptr_t Entry, rmp_ptr_t Stack);
EXTERN void _RMP_MSP430_Yield(void);
__EXTERN__ void _RMP_Yield(void);

/* Initialization */
__EXTERN__ rmp_ptr_t _RMP_Stack_Init(rmp_ptr_t Stack,
                                     rmp_ptr_t Size,
                                     rmp_ptr_t Entry,
                                     rmp_ptr_t Param);
__EXTERN__ void _RMP_Lowlvl_Init(void);
__EXTERN__ void RMP_Putchar(char Char);
__EXTERN__ void _RMP_Plat_Hook(void);
/*****************************************************************************/
/* Undefine "__EXTERN__" to avoid redefinition */
#undef __EXTERN__
/* __RMP_PLATFORM_MSP430_MEMBERS__ */
#endif
/* !(defined __HDR_DEFS__||defined __HDR_STRUCTS__) */
#endif
/* End Public C Function Prototypes ******************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
