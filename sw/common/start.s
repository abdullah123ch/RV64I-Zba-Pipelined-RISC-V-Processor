.section .text.init
.global _start

/*
 * File: sw/common/start.s
 * Brief: Minimal assembly start-up for bare-metal simulation.
 * Sets up stack pointer and calls `main` then spins.
 */
 
_start:
    la sp, _stack_top
    andi sp, sp, -16
    call main

_exit:
    mv x31, a0    # Result of 'return sum' from C goes into x31
loop:
    j loop