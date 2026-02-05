/*
 * File: sw/common/start.s
 * Brief: Bare-metal RISC-V assembly startup code for simulation.
 * Initializes stack pointer, calls main() C function, and spins in exit loop.
 * Stack grows downward; x31 reserved for test success indicator (checksum return).
 */

.section .text.init                             // place in .text.init section (loaded at 0x0)
.global _start                                  // export _start as entry point

/*
 * ========================================================
 * _START: ENTRY POINT (BOOTLOADER)
 * ========================================================
 * Executes immediately when processor starts
 * Responsibilities:
 *   1. Set up stack pointer (grows downward in memory)
 *   2. Call main() function (application code)
 *   3. Move return value from main() to x31 for test verification
 *   4. Spin in infinite loop
 */
_start:
    la sp, _stack_top                          // load address of stack top into sp
                                                // sp will grow downward from this address
    andi sp, sp, -16                           // align sp to 16-byte boundary (ABI requirement)
                                                // -16 in binary: ...11110000, so AND clears lower 4 bits
    
    call main                                   // call main() C function
                                                // return value (a0) will be left in x10 (a0)

/*
 * ========================================================
 * _EXIT: EXIT HANDLER
 * ========================================================
 * After main() returns, transfer return value to x31
 * x31 is used by testbench to verify test success
 * (testbench checks if x31 == 0x7FF for success marker)
 */
_exit:
    mv x31, a0                                 // move return value from a0 (x10) to x31
                                                // test uses x31 value (0x7FF) to detect success
/*
 * ========================================================
 * SPIN LOOP: INFINITE LOOP
 * ========================================================
 * Continuously jump to self (simulates processor idle)
 * Prevents processor from executing garbage code after main()
 */
loop:
    j loop                                      // jump to self: infinite loop