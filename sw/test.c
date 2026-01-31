__attribute__((section(".text")))
void _start() {
    asm volatile (
        // Test 1: Manual Word Overflow
        "addi t0, x0, 1;"
        "slli t0, t0, 31;"   // t0 = 0x0000000080000000 (NOT sign extended yet)
        "addi t0, t0, -1;"   // t0 = 0x000000007FFFFFFF
        "addiw s1, t0, 1;"   // s1 should become ffffffff80000000
        
        // Test 2: SUBW
        "addi t2, x0, 1;"
        "addi t3, x0, 2;"
        "subw s2, t2, t3;"   // s2 should become ffffffffffffffff

        // Success Marker
        "li x31, 0x7ff;"
    );
}