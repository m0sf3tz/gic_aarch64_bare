/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (C) 2013, 2014 ARM Limited, All Rights Reserved.
 * Author: Marc Zyngier <marc.zyngier@arm.com>
 */
#pragma once

#define GICD_CTLR           0x0000
#define GICD_TYPER          0x0004
#define GICD_IIDR           0x0008
#define GICD_TYPER2         0x000C
#define GICD_STATUSR        0x0010
#define GICD_SETSPI_NSR     0x0040
#define GICD_CLRSPI_NSR     0x0048
#define GICD_SETSPI_SR      0x0050
#define GICD_CLRSPI_SR      0x0058
#define GICD_IGROUPR        0x0080
#define GICD_ISENABLER      0x0100
#define GICD_ICENABLER      0x0180
#define GICD_ISPENDR        0x0200
#define GICD_ICPENDR        0x0280
#define GICD_ISACTIVER      0x0300
#define GICD_ICACTIVER      0x0380
#define GICD_IPRIORITYR     0x0400
#define GICD_ICFGR          0x0C00
#define GICD_IGRPMODR       0x0D00
#define GICD_NSACR          0x0E00
#define GICD_IGROUPRnE      0x1000
#define GICD_ISENABLERnE    0x1200
#define GICD_ICENABLERnE    0x1400
#define GICD_ISPENDRnE      0x1600
#define GICD_ICPENDRnE      0x1800
#define GICD_ISACTIVERnE    0x1A00
#define GICD_ICACTIVERnE    0x1C00
#define GICD_IPRIORITYRnE   0x2000
#define GICD_ICFGRnE        0x3000
#define GICD_IROUTER        0x6000
#define GICD_IROUTERnE      0x8000
#define GICD_IDREGS         0xFFD0
#define GICD_PIDR2          0xFFE8

#define ESPI_BASE_INTID     4096

#define GICD_CTLR_RWP         (1U << 31)
#define GICD_CTLR_DS          (1U << 6)
#define GICD_CTLR_ARE_S       (1U << 5)
#define GICD_CTLR_ARE_NS      (1U << 4)
#define GICD_CTLR_ENABLE_G1A  (1U << 1)
#define GICD_CTLR_ENABLE_G1   (1U << 0)

#define QEMU_BASE_GICV3 (0x08000000)
#define GIC_SET_VALUE(REG, BIT)                                       \
  do {                                                                \
  uint32_t reg = ( *(volatile uint32_t*)( (REG) + QEMU_BASE_GICV3) ); \
  reg |= (1U << (BIT));                                               \
  ( *(volatile uint32_t*)( (REG) + QEMU_BASE_GICV3) ) = reg;          \
} while(0)
  
