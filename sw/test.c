void __attribute__((naked)) _start() {
    asm volatile (
        // 1. Setup registers (addi) - 64-bit sign extended
        "addi x5, x0, 10;"      // x5 = 10
        "addi x6, x0, 20;"      // x6 = 20
        
        // 2. Arithmetic (R-type)
        "add  x7, x5, x6;"      // x7 = 30
        
        // 3. Zba Extension Test (sh1add)
        // Calculation: (x5 << 1) + x6 => (10 * 2) + 20 = 40
        ".insn r 0x33, 0x2, 0x10, x9, x5, x6;" 

        // 4. Memory Ops (sd/ld - 64-bit double words)
        "sd   x9, 8(x0);"       // Store 40 at Address 8 (aligned to 8 bytes)
        "ld   x8, 8(x0);"       // Load 40 back into x8
        
        // 5. Branching (beq)
        "beq  x8, x9, pass;"    // If 40 == 40, jump to 'pass'
        "addi x10, x0, 404;"    // FAIL CODE (should be skipped)
        
        "pass:"
        // 6. Jump and Link (jal)
        "jal  x1, end;"         // Jump to end
        "addi x10, x0, 500;"    // Should be skipped
        
        "end:"
        "addi x10, x0, 100;"    // SUCCESS CODE: x10 = 100 (0x64)
        "loop: j loop;"         // Infinite loop
    );
}