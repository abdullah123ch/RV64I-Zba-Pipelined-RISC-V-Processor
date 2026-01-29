__attribute__((section(".text")))
void _start() {
    asm volatile (
        // --- 1. Arithmetic & Forwarding Stress ---
        "li t0, 100;"        // t0 = 100
        "addi t1, t0, 50;"   // t1 = 150 (Forwarding E->E)
        "sub t2, t1, t0;"    // t2 = 50  (Forwarding M->E)
        
        // --- 2. Logical & Immediate ---
        "andi t3, t2, 0xF0;" // t3 = 50 & 0xF0 -> 32 (0x20)
        "ori  t4, t3, 0x0F;" // t4 = 32 | 0x0F -> 47 (0x2F)
        "xori t5, t4, 0xFF;" // t5 = 0x2F ^ 0xFF -> 208 (0xD0)

        // --- 3. Shifts (Logical & Arithmetic) ---
        "slli a0, t2, 2;"    // a0 = 50 << 2 = 200
        "srli a1, a0, 1;"    // a1 = 200 >> 1 = 100
        "li   a2, -1;"       // a2 = 0xFFFFFFFFFFFFFFFF
        "srai a3, a2, 4;"    // a3 = Should stay 0xFF... (Arithmetic shift preserves sign)

        // --- 4. Memory Instructions (Doubleword) ---
        "li   s0, 0x200;"    // Base address
        "sd   a1, 0(s0);"    // Store 100 at 0x200
        "sd   t5, 8(s0);"    // Store 208 at 0x208
        "ld   s1, 0(s0);"    // Load 100 back into s1
        "ld   s2, 8(s0);"    // Load 208 back into s2
        
        // --- 5. Final Checksum ---
        // If s1 + s2 == 308 (0x134), we are golden.
        "add  x31, s1, s2;"  // x31 = 308
        "li   t6, 0x7FF;"    // Success flag in T6 (x31's alias in some views)
        
        "done: j done;"
    );
}