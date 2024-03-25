#include <stdint.h>

#include "generic_timer.h"

void timer_el1_physical_init(uint64_t const next_int_cycles){
  // Disable the counter
  uint32_t reg_val = CNTP_CTL_IMASK;
  __asm__ volatile("msr CNTP_CTL_EL0, %0":: "r"(reg_val));

  __asm__ volatile("msr CNTP_TVAL_EL0, %0" :: "r"(next_int_cycles));

  // Start the counter
  // Enable interrupt generation
  reg_val = CNTP_CTL_ENABLE;
  __asm__ volatile("msr CNTP_CTL_EL0, %0":: "r"(reg_val));
}

void timer_el1_physical_rearm(uint64_t next_int_cycles){
  // Disable the timer
  uint32_t reg_val = 0;
  __asm__ volatile("msr CNTP_CTL_EL0, %0":: "r"(reg_val));

  // Add next_int_cycles to the current time and store that in the 
  // timer comparator
  __asm__ volatile("msr CNTP_TVAL_EL0, %0" :: "r"(next_int_cycles));

  // Enable the timer
  reg_val = CNTP_CTL_ENABLE;
  __asm__ volatile("msr CNTP_CTL_EL0, %0":: "r"(reg_val));
}
