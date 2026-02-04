OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text : {
    *(.text.init)
    *(.text)
  }

  /* Ensure data doesn't overlap with your code space */
  . = 0x00001000; 
  .data : { *(.data) }
  .bss  : { *(.bss) }

  _stack_top = 0x00001FF0; 
}