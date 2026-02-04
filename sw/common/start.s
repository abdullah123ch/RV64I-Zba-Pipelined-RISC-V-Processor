.section .text.init
.global _start

_start:
    la sp, _stack_top
    andi sp, sp, -16
    call main

_exit:
    mv x31, a0    # Result of 'return sum' from C goes into x31
loop:
    j loop