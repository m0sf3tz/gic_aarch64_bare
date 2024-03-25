# Compiler settings
CROSS_PREFIX := aarch64-linux-gnu-
CC           := $(CROSS_PREFIX)gcc
AS           := $(CROSS_PREFIX)as
LD           := $(CROSS_PREFIX)ld
CFLAGS       := -c -g -ffreestanding 
OUTPUT       := kernel.elf
C_SRC        := generic_timer.c  gicv3_basic.c  gicv3_setup.c  irq.c  kernel.c 
AS_SRC       := boot.S gicv3_cpuif.S
OBJS         := $(patsubst %.c,%.o,$(C_SRC)) $(patsubst %.S,%.o,$(AS_SRC))

.PHONY: clean all

# Default target
all : $(OUTPUT)

# Delete all the object files + the kernel.elf 
clean:
	rm -rf *.o $(OUTPUT)

# Link the executable
$(OUTPUT) : $(OBJS)
	$(LD) -Tlinker.ld $(OBJS) -o $@

# Compile each c files
%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

# Compile each ASM files
%.o: %.S
	$(AS) $< -o $@

# Note, if you want to make changes to the program without wrestling with a makefile, you can run the following commands:
#
#  aarch64-linux-gnu-gcc -c -g -ffreestanding  generic_timer.c -o generic_timer.o
#  aarch64-linux-gnu-gcc -c -g -ffreestanding  gicv3_basic.c -o gicv3_basic.o
#  aarch64-linux-gnu-gcc -c -g -ffreestanding  gicv3_setup.c -o gicv3_setup.o
#  aarch64-linux-gnu-gcc -c -g -ffreestanding  irq.c -o irq.o
#  aarch64-linux-gnu-gcc -c -g -ffreestanding  kernel.c -o kernel.o
#  aarch64-linux-gnu-as boot.S -o boot.o
#  aarch64-linux-gnu-as gicv3_cpuif.S -o gicv3_cpuif.o
#  aarch64-linux-gnu-ld -nostdlib -Tlinker.ld generic_timer.o gicv3_basic.o gicv3_setup.o irq.o kernel.o boot.o gicv3_cpuif.o -o kernel.elf
