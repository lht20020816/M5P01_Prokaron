/******************************************************************************
Filename   : rmp_platform_stm32l071cb_rvm.h
Author     : pry
Date       : 24/06/2017
Licence    : The Unlicense; see LICENSE for details.
Description: The configuration file for STM32L071CB.
******************************************************************************/

/* Define ********************************************************************/
/* Debugging */
#define RMP_ASSERT_CORRECT          (0U)
/* The maximum number of preemption priority levels in the system.
 * This parameter must be divisible by the word length - 32 is usually sufficient */
#define RMP_PREEMPT_PRIO_NUM        (32U)
/* The maximum number of slices allowed */
#define RMP_SLICE_MAX               (100000U)
/* The maximum number of semaphore counts allowed */
#define RMP_SEM_CNT_MAX             (1000U)
/* Are we using custom hooks? */
#define RMP_HOOK_EXTRA              (0U)
/* The stack size of the init thread */
#define RMP_INIT_STACK_SIZE         (1024U)

/* The mask/unmask interrupt operations */
#define RMP_INT_MASK()              RMP_Int_Mask()
#define RMP_INT_UNMASK()            RMP_Int_Unmask()

/* Whether to use fast yield routine */
#define RMP_A6M_RVM_FAST_YIELD      (1U)
/* End Define ****************************************************************/

/* End Of File ***************************************************************/

/* Copyright (C) Evo-Devo Instrum. All rights reserved ***********************/
