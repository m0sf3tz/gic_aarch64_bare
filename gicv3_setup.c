#include "gicv3_basic.h"
#include "gicv3_registers.h"

#include "irq.h"   
#include "generic_timer.h"

#define GIC_BASE                    (0x08000000)
#define GIC_CPU_INTF                (0x08010000)
#define GIC_REDIST                  (0x080A0000)
 
uint32_t getAffinity(void);
uint32_t GIC_REDIST_ID;

void gic_init(void){ 
  setGICAddr((void *)GIC_BASE, (void *)GIC_REDIST);
  enableGIC();

  GIC_REDIST_ID = getRedistID(getAffinity());
  wakeUpRedist(GIC_REDIST_ID);
  
  setPriorityMask(0xFF);

  enableGroup1Ints();
}   
  
void gic_register_device(uint64_t _device_id){ 
  setIntType(_device_id, GIC_REDIST_ID, GICV3_CONFIG_LEVEL);
  setIntPriority(_device_id, GIC_REDIST_ID, 0);
  setIntGroup(_device_id, GIC_REDIST_ID, GICV3_GROUP1_NON_SECURE);
  enableInt(_device_id, GIC_REDIST_ID);
}

void config_interrupts(){
  gic_init();                        // Sets up GIC
  gic_register_device(TIMER_IRQ);    // Enables the timer interrupt
}

void post_interrupt(){
  set_interrupt_sgi_ppi(TIMER_IRQ, GIC_REDIST_ID);
}

void start_el1_physical_timer_interrupt(){
  // Enables/unmasks the EL1 Physical timer
  timer_el1_physical_init(EL1_TIMER_PERIOD);
  
  // Unmask the interrupt
  IRQ_ENABLE;
}
