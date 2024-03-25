#include "aarch64_regs.h"

.global _start
_start:
  // Setup the vector table for EL3 (Note, in this example all interupts are handled in EL1)
  LDR X1, =vector_table_el3
  MSR VBAR_EL3, X1
  ISB

  // Enable the System Register Interface for the GIC for both EL1 and EL3
  MOV X0, #1   
  MSR ICC_SRE_EL1, X0   
  MSR ICC_SRE_EL3, X0

  MOV x1, XZR            // Initial value of register is unknown
  ORR x1, x1, #(1 << 10) // Set RW bit (EL1 is AArch64, as this is the Secure world)
  ORR x1, x1, #(1 << 5)  // RES1
  ORR x1, x1, #(1 << 4)  // RES1
  ORR x1, x1, #(1 << 0)  // NS EL0/EL1 is Non-secure world.
  MSR SCR_EL3, x1
  ISB  

  // Enable Group1NS interrupt for both EL1 and El3
  MOV X0, #1   
  MSR ICC_IGRPEN1_EL3, X0
  ISB 

  // Setup EL2
  MOV X0, #0b0100   // DAIF=0000
  MSR SPSR_EL3, X0  // sets M[3:0] to EL0 with sp_el1
  ADR X0, el1_entry // el1_entry points to the first instruction of
  MSR ELR_EL3, X0   // EL1 entry.

  msr  SPsel, #1         // Use the SP_EL3 stack not SP_EL0
  ldr x1,=stack_top_el3  // Set the stack for EL3 (SP_EL3)
  MOV sp,x1              // Update the stack pointer

  // bl bss_data_init    // zero out the BSS (not needed - QEMU zeros out RAM)
  bl config_interrupts   // Sets up the GIC and also installs the timer interupts 

  // Go to EL1  
  ERET

el1_entry:
  // Setup the vector table for EL1 
  // Note, in this example we will actually handle IRQs in EL1
  LDR X1, =vector_table_el1
  MSR VBAR_EL1, X1
  ISB 
  
  // Setup El0
  MOV X0, #0b0000   // DAIF=0000
  MSR SPSR_EL1, X0  // sets M[3:0] to EL1 with sp_el1
  ADR X0, el0_entry // el1_entry points to the first instruction of
  MSR ELR_EL1, X0   // EL0 entry code.

  msr  SPsel, #1    // Want to use SP_EL1, we can also set SPsel in which case we will take the IRQ in

  ldr x1,=stack_top_el1
  MOV sp,x1

  bl start_el1_physical_timer_interrupt
 
  ERET

el0_entry:
  ldr x1,=stack_top_el0
  MOV sp,x1

  bl kmain 

.balign 0x800
vector_table_el3:
curr_el3_sp0_sync:
  b . 

.balign 0x80
curr_el3_sp0_irq:
  b . 

.balign 0x80
curr_el3_sp0_fiq:
  b . 

.balign 0x80
curr_el3_sp0_serror:
  b . 

.balign 0x80
curr_el3_spx_sync:
  b . 

.balign 0x80
curr_el3_spx_irq:
  b . 

.balign 0x80
curr_el3_spx_fiq:
  b . 

.balign 0x80
curr_el3_spx_serror:
  b . 

.balign 0x80
lower_el3_aarch64_sync:
  b .

.balign 0x80
lower_el3_aarch64_irq:
  b .

.balign 0x80
lower_el3_aarch64_fiq:
  b .

.balign 0x80
lower_el3_aarch64_serror:
  b .

.balign 0x80
lower_el3_aarch32_sync:
  b .

.balign 0x80
lower_el3_aarch32_irq:
  b .

.balign 0x80
lower_el3_aarch32_fiq:
  b .

.balign 0x80
lower_el3_aarch32_serror:
  b .


// Vector table for EL1 (note, EL0 interrupts will be taken here)
.balign 0x800
vector_table_el1:
curr_el1_sp0_sync:
  b . 

.balign 0x80
curr_el1_sp0_irq:
  b .

.balign 0x80
curr_el1_sp0_fiq:
  b . 

.balign 0x80
curr_el1_sp0_serror:
  b . 

.balign 0x80
curr_el1_spx_sync:
  b . 

.balign 0x80
curr_el1_spx_irq:
  b .

.balign 0x80
curr_el1_spx_fiq:
  b . 

.balign 0x80
curr_el1_spx_serror:
  b . 

.balign 0x80
lower_el1_aarch64_sync:
  b .

.balign 0x80
lower_el1_aarch64_irq:
  // This is where we will handle El0 interrupts (IRQ)
  b irq_handler_el1 
  eret

.balign 0x80
lower_el1_aarch64_fiq:
  b .

.balign 0x80
lower_el1_aarch64_serror:
  b .

.balign 0x80
lower_el1_aarch32_sync:
  b .

.balign 0x80
lower_el1_aarch32_irq:
  b .

.balign 0x80
lower_el1_aarch32_fiq:
  b .

.balign 0x80
lower_el1_aarch32_serror:
  b .


.global irq_handler_el1
irq_handler_el1:
  stp x29, x30, [sp, #-16]!
  stp x27, x28, [sp, #-16]!
  stp x25, x26, [sp, #-16]!
  stp x23, x24, [sp, #-16]!
  stp x21, x22, [sp, #-16]!
  stp x19, x20, [sp, #-16]!
  stp x17, x18, [sp, #-16]!
  stp x15, x16, [sp, #-16]!
  stp x13, x14, [sp, #-16]!
  stp x11, x12, [sp, #-16]!
  stp x9, x10, [sp, #-16]!
  stp x7, x8, [sp, #-16]!
  stp x5, x6, [sp, #-16]!
  stp x3, x4, [sp, #-16]!
  stp x1, x2, [sp, #-16]!

  mrs x21, spsr_el1
  stp x21, x0, [sp, #-16]!

  mrs x21, elr_el1
  stp xzr, x21, [sp, #-16]!

  // Jump to C and handle the interrupt
  bl irq_handler

  ldp x21, x22, [sp], #16
  msr elr_el1, x22

  ldp x21, x0, [sp], #16
  msr spsr_el1, x21

  ldp x1, x2, [sp], #16 
  ldp x3, x4, [sp], #16 
  ldp x5, x6, [sp], #16 
  ldp x7, x8, [sp], #16 
  ldp x9, x10, [sp], #16 
  ldp x11, x12, [sp], #16
  ldp x13, x14, [sp], #16
  ldp x15, x16, [sp], #16
  ldp x17, x18, [sp], #16
  ldp x19, x20, [sp], #16
  ldp x21, x22, [sp], #16
  ldp x23, x24, [sp], #16
  ldp x25, x26, [sp], #16
  ldp x27, x28, [sp], #16
  ldp x29, x30, [sp], #16

  eret
