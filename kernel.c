#include <stdint.h>

#include "gicv3.h"
#include "irq.h"

// QEMU specfic  
volatile uint8_t *uart = (uint8_t *) 0x09000000;
 
void putchar(char c) {
  *uart = c;
}
 
void print(const char *s) {
  while(*s != '\0') {
    putchar(*s);
    s++;
  }
}

// Note, we don't need this really since QEMU sets up BSS/DATA section 
void bss_data_init(){
  // Set in linker script
  extern char __bss_start; 
  extern char __bss_end;
  int bss_size = &__bss_end - &__bss_start;

  uint8_t * ptr = &__bss_start;
  while(bss_size--){
    *ptr++ = 0;
  }
 
  // TODO: setup data section
}

// Entry point into EL0 code
void kmain() {
  
  // Wait forever, we will take IRQs here and vector to EL1
  // where we will handle the interrupt and return 
  while (1) {
  }
}
