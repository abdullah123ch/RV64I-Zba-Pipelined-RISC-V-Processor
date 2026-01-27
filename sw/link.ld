/* link.ld - Simple linker script for RISC-V Pipeline */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  /* Instruction Memory starts at 0x0 */
  . = 0x0;
  .text : {
    *(.text.init)
    *(.text)
  }

  /* Data Memory - simplified to follow code */
  . = ALIGN(0x1000);
  .data : {
    *(.data)
  }

  .bss : {
    *(.bss)
  }

  _end = .;
}