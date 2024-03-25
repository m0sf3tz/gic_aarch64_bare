#include "irq.h"
#include "generic_timer.h"

void __arch_enable_irq(void) {
 __asm__ volatile ("msr DAIFClr, %0" :: "i"(DAIF_IRQ_BIT));
 return;
}

void __arch_disable_irq(void) {
	__asm__ volatile("msr DAIFSet, %0" :: "i"(DAIF_IRQ_BIT));
  return;
}

// In EL1, the way we have configured the system  the only interrupt 
// that should get routed is an NS Group 1 interrupt
static inline uint32_t get_interrupt_id(void) {
  uint32_t INTID;
  __asm__ volatile("mrs %0, ICC_IAR1_EL1" : "=r"(INTID));
  return INTID;
}

// In EL1, the way we have configured the system  the only interrupt 
// that should get routed is an NS Group 1 interrupt
static inline uint32_t clear_interrupt(uint32_t intid){
  uint32_t reg_val = intid;
  __asm__ volatile("msr ICC_EOIR1_EL1, %0" : : "r"(reg_val));
}

// IRQ handler, called from Assembly
void irq_handler(){
  uint32_t intid = get_interrupt_id();
  
  // Assuming we only get timer interrupts
  // lets hang here if this is not true.
  if(intid != TIMER_IRQ){
    while(1);
  }

  clear_interrupt(intid);
 
  timer_el1_physical_rearm(50000000);
}
