/*
 * File: sw/common/link.ld
 * Brief: GNU LD linker script for bare-metal RISC-V simulation.
 * Configures memory layout:
 *   - .text (code): starts at 0x00000000
 *   - .data (initialized globals): starts at 0x00001000
 *   - .bss (uninitialized globals): follows .data
 *   - Stack: grows downward from 0x00001FF0
 */

OUTPUT_ARCH( "riscv" )                          // specify RISC-V architecture
ENTRY(_start)                                   // entry point is _start label

SECTIONS
{
  /* ========================================================
   * TEXT SECTION (CODE AND RO DATA)
   * ======================================================== */
  . = 0x00000000;                               // set address counter to 0x0
  .text : {                                     // create .text output section
    *(.text.init)                               // include startup code (start.s) first
    *(.text)                                    // include all other code sections
  }

  /* ========================================================
   * DATA SECTION (INITIALIZED GLOBAL VARIABLES)
   * ======================================================== */
  /* Ensure data doesn't overlap with code (1KB gap) */
  . = 0x00001000;                               // set address counter to 0x1000 (code ends earlier)
  .data : {                                     // create .data output section
    *(.data)                                    // include all initialized global variables
  }

  /* ========================================================
   * BSS SECTION (UNINITIALIZED GLOBAL VARIABLES)
   * ======================================================== */
  /* BSS follows data in memory, but occupies no space in file */
  .bss  : {                                     // create .bss output section
    *(.bss)                                     // include all uninitialized global variables
  }

  /* ========================================================
   * STACK REGION
   * ======================================================== */
  _stack_top = 0x00001FF0;                      // stack grows downward from this address
                                                // start.s loads sp with this value and aligns to 16 bytes
}
