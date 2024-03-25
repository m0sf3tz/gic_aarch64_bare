#ifndef IRQ_H
#define IRQ_H

#include <stdint.h>

#define DAIF_IRQ_BIT (1 << 1) /* IRQ mask bit */
#define DAIF_FIQ_BIT (1 << 0) /* FIQ mask bit */

#define IRQ_ENABLE   __asm__ volatile ("msr DAIFClr, %0" :: "i"(DAIF_IRQ_BIT));
#define IRQ_DISABLE  __asm__ volatile ("msr DAIFSet, %0" :: "i"(DAIF_IRQ_BIT));
 
void __arch_enable_irq(void);
void __arch_disable_irq(void);

void __arch_end_of_interrupt(uint64_t);
uint32_t __arch_acknowledge_interrupt(void);

#endif
