__attribute__((section(".text")))
void _start() {
    asm volatile (
        ".rept 10; nop; .endr;"
        "li s0, -200;"                // x8 = 0xFFFFFFFFFFFFFF38 (Two's complement)
        "li s1, 50;"                  // x9 = 50
        
        // 1. sh1add s2, s1, s0 
        // Logic: (50 << 1) + (-200) = 100 - 200 = -100
        // Expected x18: 0xFFFFFFFFFFFFFF9C
        ".insn r 0x33, 0x2, 0x20, x18, x9, x8;"

        // 2. sh2add s3, s2, s1
        // Logic: (-100 << 2) + 50 = -400 + 50 = -350
        // Expected x19: 0xFFFFFFFFFFFFFEA2
        ".insn r 0x33, 0x4, 0x20, x19, x18, x9;"

        "li x31, 0x7FF;"
        "finish: j finish;"
    );
}