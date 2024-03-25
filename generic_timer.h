#pragma once 

#include <stdint.h>

#define CNTP_CTL_ENABLE         (1 << 0)    /* Enables the timer */
#define CNTP_CTL_IMASK          (1 << 1)    /* Timer interrupt mask bit */
#define CNTP_CTL_ISTATUS        (1 << 2)    /* The status of the timer interrupt. This bit is read-only */

#define EL1_TIMER_PERIOD        (50000000)
#define TIMER_IRQ			         	(30)        /* EL1 Physical Timer */

// Enables EL1 physical timer and kicks it off
void timer_el1_physical_init(uint64_t const);

// Restart the timer  
void timer_el1_physical_rearm(uint64_t const);
