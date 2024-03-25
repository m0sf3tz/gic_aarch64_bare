
## AARCH64 BareMetal GIC minimum implementation 

### Credits 
Hello, welcome to my notes on getting the GIC to work on a AARCH64 processor in QEMU. I'm sure I missed a lot of things, but hopefully I have captured the big picture.

Before proceeding - I need to give credit to the following:

https://github.com/m8/armvisor \
https://github.com/NienfengYao/armv8-bare-metal \
https://www.nxp.com/docs/en/supporting-information/FTF-DES-N1849-PDF.pdf

I "lifted" various chunks of my code from these repositories (plus other places I found on the web). Nevertheless, I like to think what follows is different enough from the above to warrant a small write up - and hopefully help cover some topics that the above two tutorials/repositories didn't cover.

### Overview 

The code in this project is meant to run on a typical ARM cortex processor in an embedded setting using EL3, EL1 and El0. Use of virtualisation (EL2) in pure embedded applications is rare - at least compared to the server world so it is not taken into account here. 

The code does the following:
 - starts off in EL3
   - sets up SCR_EL3 to indicate that El1/EL0 are non-secure
   - sets up VBAR for EL3 (This example should never take any interrupts to EL3, however)
   - Sets up the stack pointer for EL3
   - Initiates the GIC, enables group 1 (unsecure) interrupts
   - switches to EL1 (kernel)
 - In EL1:
   -  Sets up the VBAR for EL1 (Unlike the VBAR for El3 - we do expect to take interrupts to EL1)
   -  sets up stack for EL1
   -  Kicks off the timer interrupt
   -  Switch to EL0
 -  In EL0
      -  We will spin in a forever loop - IRQs will be routed to El1 (kernel)

### Enabling interrupts

First things first - our goal is to enable interrupts on an AARCH64 processor. To keep things simple - we won't enable interrupt preemption.

We need to do 
two things:

A) Enable the GIC,\
B) Enable our interrupt source,

There are different ways of configuring the GIC, for the GICv3+, ARM recommends using Affinity routing with the CPU interface set to use system register (IE, not memory mapped) so that is what we will do.

The simplest interrupt source we can use is probably the Physical EL1 timer. We set up this interrupt to fire once every second by noting that EL1 timer frequency in QEMU is 50Mhz, so we use CNTP_TVAL_EL0 to set a trigger point 1 second in the future.

In GICv3/GICv4 - which is what you will find on most new ARM processors, there are several different kinds of interrupts, 

 - SPI (Shared Peripheral Interrupt)
   - This is a global peripheral interrupt that can be routed to a specified PE, or to one of a group of PEs
 - PPI (Private Peripheral Interrupt)
   - This is peripheral interrupt that targets a single, specific PE. An example of a PPI is an interrupt from the Generic Timer of a PE.
- SGI / LPIs
  -  not covered

*(Credit ARM: GICv3 Software Overview Official Release)*

It's important to remember that a typical timer in an SoC would usually be considered a SPI - however, the Generic Timers are ARM IPs which are closely coupled to an individual PE, hence, they are PPI not a SPI.

From a software exception handling point of view, this is not really important- but when we want to install a PPI we need to configure the redistributors, while SPIs are handled by the GIC distributor.

![redis](https://github.com/m0sf3tz/AARCH64_GIC_BARE/assets/16571423/cb6ba4cb-402b-4ff6-ace2-6ab39dcb9c50)
(Credit ARM: GICv3/v4 Software Overview Official Release)

Roughly speaking, we need to do the following to set up the GIC.

 - Enable affinity routing (this is the new way of routing interrupts in GICv3+). Set GICD_CTRL.ARE_S and GICD_CTRL.ARE_NS to enable affinity routing. (see **enableGIC()**)
 - Enable the routing of group1 interrupts. Since we plan on taking interrupts in EL1/0 NS - this is the only interrupt we need to enable distribution of. (see **enableGIC()**)
 - Wake up the redistributer (see **wakeUpRedist()**)
 - Enable the CPU register interface to the CPU interface, (set the SRE flag in **ICC_SRE_EL1** and **ICC_SRE_EL3**)
 - Enable signaling of interrupts to the PE by:
   - Set the **EnableGrp1NS** bit in **ICC_IGRPEN1_EL3** to enable routing of Non-secure group1 interrupts
   - Set the lowest priority interrupt the CPU will accept, stored in **ICC_PMR_EL1**
 
Now the GIC should be set up, the next step is to actually enable a particular interrupt we are interested in. PPIs need to be enabled through the redistributes. 

 - Set the priority stored in(**GICR_IPRIORITYRn**) - where **n** is the INTID for the interrupt we are interested in.
 - Set the group and security for the interrupt, see **setIntGroup()**
 - Set the Level/edge configuration for the interrupt to match the interrupt source (Generic ARM timers are level triggered), see **setIntType()**
 - Finally enable the interrupt, see **enableInt()**
 
 Remember, we still need to unmask interrupts using **PSTATE.I/F**

## Security model

As a final note, we need to consider FIQ/IRQ handling in AARCH64 is starkly different to AARCH32 and most other embedded SoCs. Usually, the **F** in **F**IQ stands for *fast* - as in the CPU hardware does some work behind the scene to ensure FIQs are taken more quickly than IRQs. For example in some real-time processors an FIQ might automatically bank certain CPU registers in FIQ mode to save a few cycles when handling a time critical interrupt.

This is not true for AARCH64 - the distinction between IRQs and FIQs is now not speed - but rather security. GICv3/4 supports three different types of interrupts:

| Interrupt Type | Example |
|--|--|
|Secure Group 0  |Interrupts for EL3 (Secure Firmware) |
| Secure Group 1 | Interrupts for Secure EL1 (Trusted OS) |
|Non-secure Group 1|Interrupts for the Non-secure state (OS or Hypervisor)|
|  |  |

To determine if something is signaled as an FIQ or IRQ, we can refer to the following table. 

| Current Exception Level | Group 0 interrupts  | Group 1 Secure  | Group 1 non-secure| 
|--|--|--|--|
| Secure El0/El1 | FIQ |IRQ | FIQ |
| Non-Secure El0/EL1 | FIQ |FIQ | IRQ |
| Non-Secure El2 | FIQ |FIQ | IRQ |
| EL3 | FIQ |FIQ |FIQ |
|  |  | | 

It's evident from the above table Group0 interrupts are always routed as FIQ, while group1 NS/S depend on the current configuration of the PE.

What's more, the SCR_EL3.FIQ and SCR_EL3.IRQ register controls which EL an interrupt gets routed too. 

![Screenshot from 2024-03-24 16-54-34](https://github.com/m0sf3tz/AARCH64_GIC_BARE/assets/16571423/a57cf543-2d09-4578-b320-7fa6115ac647)
*(Credit ARM: GICv3/v4 Software Overview Official Release)*

In the above configuration, if a NS Group1 interrupts fires while we are in NS world, we handle the interrupt as an IRQ and stay in the NS world, but if either a secure group 0 or group 1 interrupt comes, we switch to the secure world and enter El3. If the interrupt was meant to be handled in El3 (group0) it is directly handed - but if it was an interrupt meant for Secure El1, the firmware at El3 is responsible for switching to El1 secure and letting the EL1 secure firmware handler the interrupt. 

The corollary  is true from the secure world. 

### Building and  Testing

To build the firmware, simply run 
  
>  $ make 


Before we start trying out the timers, we can do a dry run. the ARM GIC has registers which allow posting interrupts. We can use these interrupts to see if we have set up the core properly or not.

we can call **set_interrupt_sgi_ppi** in either EL1 or El0 to simulate a timer interrupt. In either case, we should expect El1 to handle the interrupt. Placing 

>  b .

Instructions in the VBAR handlers for EL1 is helpful for catching interrupts here.

To get some debug statements, start QEMU like this
  
>   qemu-system-aarch64 -M virt,secure=on,gic-version=3   -cpu cortex-a53  -nographic -kernel kernel.elf -gdb tcp::1236
   
Now connect to the QEMU backend using the following GDB command

>  aarch64-none-elf-gdb -ex 'target remote localhost:1236' -ex 'monitor log int' --tui

The "monitor log int" Should make QEMU emit debug logs on every EL change.

We should see something like this 
   
> Exception return from AArch64 EL1 to AArch64 EL0 PC 0x40103550\
> Taking exception 5 [IRQ]\
> ...from EL0 to EL1\
> ...with ESR 0x0/0x0\
> ...with ELR 0x40103550\
> ...to EL1 PC 0x40101480 PSTATE 0x3c5\
> Exception return from AArch64 EL1 to AArch64 EL0 PC 0x40103550\
> Taking exception 5 [IRQ]\
> ...from EL0 to EL1\
> ...with ESR 0x0/0x0\
> ...with ELR 0x40103550\
> ...to EL1 PC 0x40101480 PSTATE 0x3c5\
> Exception return from AArch64 EL1 to AArch64 EL0 PC 0x40103550\
> Taking exception 5 [IRQ]\
> ...from EL0 to EL1\
> ...with ESR 0x0/0x0\
> ...with ELR 0x40103550\
> ...to EL1 PC 0x40101480 PSTATE 0x3c5\
> Exception return from AArch64 EL1 to AArch64 EL0 PC 0x40103550\
> Taking exception 5 [IRQ]\
> ...from EL0 to EL1\
> ...with ESR 0x0/0x0\
> ...with ELR 0x40103550\
> ...to EL1 PC 0x40101480 PSTATE 0x3c5\
> Exception return from AArch64 EL1 to AArch64 EL0 PC 0x40103550\


