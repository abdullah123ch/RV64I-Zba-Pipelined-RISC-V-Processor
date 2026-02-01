__attribute__((section(".text")))
void _start() {
    asm volatile (
        "li sp, 0x1000;"              // 1. Initialize SP
        "li s1, 0xDEADBEEFC0DE5555;"  // 2. Load 64-bit pattern
        
        "addi sp, sp, -16;"           // 3. Move SP
        "sd s1, 8(sp);"               // 4. Store to Stack (0x1008)
        
        "li s1, 0;"                   // 5. Clear register
        "ld s2, 8(sp);"               // 6. Load from Stack (Should be pattern)
        "addi sp, sp, 16;"            // 7. Restore SP
        
        "mv x31, s2;"                 // 8. Result to T6
        "finish: j finish;"
    );
}