ENTRY(_start)
SECTIONS {
    . = 0x40100000; /* RAM starts at 0x40000000 but if we ask to load the kernel there, QEMU will not load a DTB */
    .startup . : { boot.o(.text) }
    . = ALIGN(128);
    .text : { *(.text) }
    . = ALIGN (CONSTANT (COMMONPAGESIZE)); /* see https://www.redhat.com/en/blog/linkers-warnings-about-executable-stacks-and-segments (The executable segment warnings) */
    .data : { *(.data) }
    . = ALIGN (CONSTANT (COMMONPAGESIZE));
    .bss : {
      __bss_start = .;
      *(.bss COMMON)
      __bss_end   = .;
     }
    . = ALIGN (CONSTANT (COMMONPAGESIZE));
    . += 0x1000; /* 4kB of stack memory */
    stack_top_el0 = .;
    . = ALIGN(8);
    . += 0x1000; /* 4kB of stack memory */
    stack_top_el1 = .;
    . = ALIGN(8);
   . += 0x1000;  /* 4kB of stack memory */
    stack_top_el3 = .;
}

__bss_size = (__bss_end - __bss_start)>>3;
