// void _start() {
//     // --- 1. 64-bit Edge Cases (ADD/ADDI/SUB) ---
//     // Max 64-bit positive + 1 (Should wrap to Min Negative)
//     // 0x7FFFFFFFFFFFFFFF + 1 = 0x8000000000000000
//     asm volatile ("li x10, 0x7FFFFFFFFFFFFFFF;");
//     asm volatile ("addi x11, x10, 1;");

//     // SUB: 0 - 1 (Should be all Fs)
//     asm volatile ("li x12, 0;");
//     asm volatile ("sub x13, x12, x11;"); // 0 - (Min Negative) = Max Negative? 

//     // --- 2. 32-bit Word Edge Cases (ADDW/ADDIW/SUBW) ---
//     // Max 32-bit + 1 (Inside a 64-bit register)
//     // 0x7FFFFFFF + 1 = 0x80000000 (32-bit) -> 0xFFFFFFFF80000000 (64-bit)
//     asm volatile ("li x14, 0x7FFFFFFF;");
//     asm volatile ("addiw x15, x14, 1;");

//     // SUBW: Min Negative - 1 
//     // 0x80000000 - 1 = 0x7FFFFFFF (32-bit) -> 0x000000007FFFFFFF (64-bit)
//     asm volatile ("li x16, 0x80000000;");
//     asm volatile ("subw x17, x16, x15;"); // This will be zero/weird if SUBW fails

//     // --- 3. Zero Handling ---
//     // Subtracting a number from itself (Must set Zero flag internally)
//     asm volatile ("sub x18, x11, x11;"); // x18 should be 0

//     asm volatile ("addi x31, x0, 1;"); // Success marker
//     while(1);
// }

// void _start() {
//     // ANDI: x10 = 0xFFFFFFFFFFFFFFFF & 0x00F (Immediate)
//     // Result should be 0x000000000000000F
//     asm volatile ("li x5, -1;"); // Load all 1s
//     asm volatile ("andi x10, x5, 15;"); 

//     // AND: x11 = 0xAAAA... & 0x5555...
//     // Result should be 0 (No bits overlap)
//     asm volatile ("li x6, 0xAAAAAAAAAAAAAAAA;");
//     asm volatile ("li x7, 0x5555555555555555;");
//     asm volatile ("and x11, x6, x7;");
// }
// void _start() {
//     // 1. ORI: Set the lower bits of a zero register
//     // Expected x12: 0x0000000000000ABC
//     asm volatile ("ori x12, x0, 0x0BC;");

//     // 2. OR: Combine two halves
//     // x5 = 0xFFFFFFFF00000000
//     // x6 = 0x00000000FFFFFFFF
//     // Expected x13: 0xFFFFFFFFFFFFFFFF
//     asm volatile ("li x5, 0xFFFFFFFF00000000;");
//     asm volatile ("li x6, 0x00000000FFFFFFFF;");
//     asm volatile ("or x13, x5, x6;");

//     // Success marker
//     asm volatile ("addi x31, x0, 1;");
//     while(1);
// }
// void _start() {
//     // 1. XORI: Flip bits of 0x555...
//     // 0x555... ^ -1 (all 1s) = 0xAAA...
//     // Expected x14: aaaaaaaaaaaaaaaa
//     asm volatile ("li x5, 0x5555555555555555;");
//     asm volatile ("xori x14, x5, -1;");

//     // 2. XOR: Identity property
//     // x5 ^ x5 = 0
//     // Expected x15: 0000000000000000
//     asm volatile ("xor x15, x5, x5;");

//     // 3. XOR: Value reconstruction
//     // (A ^ B) ^ B = A
//     // Expected x16: 5555555555555555
//     asm volatile ("li x6, 0x1234567890ABCDEF;");
//     asm volatile ("xor x7, x5, x6;"); // Tmp result in x7
//     asm volatile ("xor x16, x7, x6;"); // Result back in x16

//     asm volatile ("addi x31, x0, 1;");
//     while(1);
// }

// void _start() {
//     // 1. SLLI: Logical Left (Multiply by 2^n)
//     // 0x1 << 4 = 0x10
//     asm volatile ("li x5, 1;");
//     asm volatile ("slli x10, x5, 4;");

//     // 2. SRLI: Logical Right (Divide unsigned)
//     // 0x8000000000000000 >> 1 = 0x4000000000000000
//     asm volatile ("li x6, 0x8000000000000000;");
//     asm volatile ("srli x11, x6, 1;");

//     // 3. SRAI: Arithmetic Right (Preserve Sign)
//     // 0x8000000000000000 >> 1 = 0xC000000000000000
//     asm volatile ("srai x12, x6, 1;");

//     asm volatile ("addi x31, x0, 1;");
//     while(1);
// }
// void _start() {
//     // 1. SLLIW: Shift Left Logical Immediate Word
//     // 0x0000000000000001 << 31 = 0x80000000 (32-bit)
//     // Sign-extended to 64-bit: 0xFFFFFFFF80000000
//     asm volatile ("li x5, 1;");
//     asm volatile ("slliw x10, x5, 31;");

//     // 2. SRLW: Shift Right Logical Word
//     // Take that 0xFFFFFFFF80000000 and shift right logical by 1.
//     // 32-bit: 0x80000000 >> 1 = 0x40000000
//     // Sign-extended to 64-bit: 0x0000000040000000
//     asm volatile ("li x6, 1;");
//     asm volatile ("srlw x11, x10, x6;");

//     // 3. SRAW: Shift Right Arithmetic Word
//     // 0x80000000 >> 1 (Arithmetic) = 0xC0000000
//     // Sign-extended: 0xFFFFFFFFC0000000
//     asm volatile ("sraw x12, x10, x6;");

//     asm volatile ("addi x31, x0, 1;");
//     while(1);
// }
// void _start() {
//     // 1. Manually build a distinct 64-bit value in x5
//     asm volatile ("li x5, 0x123456789ABCDEF0;");
    
//     // 2. Use a safe, aligned address in x6 (0x200)
//     asm volatile ("li x6, 0x200;");
    
//     // 3. SD: Store x5 to address in x6
//     asm volatile ("sd x5, 0(x6);");
    
//     // 4. Clear x5 so we know the load is real
//     asm volatile ("li x5, 0;");
    
//     // 5. LD: Load from address 0x200 into x31
//     asm volatile ("ld x31, 0(x6);");

//     while(1);
// }
// void _start() {
//     // 1. SLTI (Signed): 5 < 10
//     // Expected x10: 1
//     asm volatile ("li x5, 5;");
//     asm volatile ("slti x10, x5, 10;");

//     // 2. SLT (Signed): -1 vs 1
//     // -1 is 0xFFFFFFFFFFFFFFFF. In signed, -1 < 1 is TRUE.
//     // Expected x11: 1
//     asm volatile ("li x6, -1;");
//     asm volatile ("li x7, 1;");
//     asm volatile ("slt x11, x6, x7;");

//     // 3. SLTU (Unsigned): -1 vs 1
//     // In unsigned, 0xFFFFFFFFFFFFFFFF is a massive number, so -1 < 1 is FALSE.
//     // Expected x12: 0
//     asm volatile ("sltu x12, x6, x7;");

//     // 4. Boundary Test: 0 vs -1 (Unsigned)
//     // Expected x13: 1 (0 is definitely less than 18 quintillion)
//     asm volatile ("sltu x13, x0, x6;");

//     asm volatile ("addi x31, x0, 1;");
//     while(1);
// }
// void _start() {
//     // x5 = -5 (0xFFFFFFFFFFFFFFFB)
//     // x6 = 2  (0x0000000000000002)
//     // x7 = 10 (0x000000000000000A)
//     asm volatile ("li x5, -5;");
//     asm volatile ("li x6, 2;");
//     asm volatile ("li x7, 10;");

//     // --- TEST 1: Basic Signed BLT (2 < 10) ---
//     // Should jump to test2
//     asm volatile ("blt x6, x7, test2;");
//     asm volatile ("li x10, 0xBAD1;"); // Fail marker

//     asm volatile ("test2:");
//     // --- TEST 2: Negative vs Positive (-5 < 2) ---
//     // 0xFF...FB is less than 2 in signed math. Should jump to test3.
//     asm volatile ("blt x5, x6, test3;");
//     asm volatile ("li x11, 0xBAD2;"); // Fail marker

//     asm volatile ("test3:");
//     // --- TEST 3: Negative vs Negative (-5 < -1) ---
//     asm volatile ("li x8, -1;");
//     asm volatile ("blt x5, x8, success;");
//     asm volatile ("li x12, 0xBAD3;"); // Fail marker

//     asm volatile ("success:");
//     asm volatile ("li x31, 1;"); // Final success marker
//     while(1);
// }
// void _start() {
//     asm volatile ("li x5, -5;");
//     asm volatile ("li x6, 2;");
//     asm volatile ("li x7, 10;");
//     asm volatile ("li x8, 5;");

//     // --- TEST 1: Strictly Greater (10 >= 2) ---
//     // Should jump to test2
//     asm volatile ("bge x7, x6, test2;");
//     asm volatile ("li x10, 0xBAD1;"); 

//     asm volatile ("test2:");
//     // --- TEST 2: Exactly Equal (5 >= 5) ---
//     // Should jump to test3
//     asm volatile ("bge x8, x8, test3;");
//     asm volatile ("li x11, 0xBAD2;");

//     asm volatile ("test3:");
//     // --- TEST 3: Signed Boundary (2 >= -5) ---
//     // 2 is greater than a negative number. Should jump to test4.
//     asm volatile ("bge x6, x5, test4;");
//     asm volatile ("li x12, 0xBAD3;");

//     asm volatile ("test4:");
//     // --- TEST 4: The False Condition (-5 >= 2) ---
//     // This should NOT jump. x13 should be populated.
//     asm volatile ("bge x5, x6, success;"); // Should skip this jump
//     asm volatile ("li x13, 0xACE;");       // We WANT to see 0xACE in x13

//     asm volatile ("success:");
//     asm volatile ("li x31, 1;");
//     while(1);
// }
// void _start() {
//     // x5 = -5 (0xFFFFFFFFFFFFFFFB)
//     // x6 = 2  (0x0000000000000002)
//     asm volatile ("li x5, -5;");
//     asm volatile ("li x6, 2;");

//     // --- TEST 1: Unsigned Comparison (-5 < 2) ---
//     // In BLTU, this is FALSE. It should NOT jump.
//     asm volatile ("bltu x5, x6, fail_unsigned;");
    
//     // If we reach here, the branch was correctly NOT taken.
//     asm volatile ("li x10, 0xACE;"); 

//     // --- TEST 2: Basic Unsigned (2 < 10) ---
//     asm volatile ("li x7, 10;");
//     asm volatile ("bltu x6, x7, success_path;");
    
//     asm volatile ("fail_unsigned:");
//     asm volatile ("li x11, 0xBAD;"); // We don't want to see this!

//     asm volatile ("success_path:");
//     asm volatile ("li x31, 1;");
//     while(1);
// }
// void _start() {
//     // x5 = -5 (0xFFFFFFFFFFFFFFFB)
//     // x6 = 2  (0x0000000000000002)
//     asm volatile ("li x5, -5;");
//     asm volatile ("li x6, 2;");

//     // --- TEST 1: Unsigned Greater/Equal (Huge vs Small) ---
//     // x5 (Huge) >= x6 (Small) is TRUE.
//     // Should jump to test2.
//     asm volatile ("bgeu x5, x6, test2;");
//     asm volatile ("li x10, 0xBAD1;"); 

//     asm volatile ("test2:");
//     // --- TEST 2: Exactly Equal Unsigned ---
//     // Should jump to test3.
//     asm volatile ("bgeu x5, x5, test3;");
//     asm volatile ("li x11, 0xBAD2;");

//     asm volatile ("test3:");
//     // --- TEST 3: The "Mind-Bender" (Small vs Huge) ---
//     // 2 >= -5 (Unsigned) is FALSE.
//     // It should NOT jump.
//     asm volatile ("bgeu x6, x5, success_label;");
    
//     // If we reach here, the logic is PERFECT.
//     asm volatile ("li x12, 0xACE;"); 

//     asm volatile ("success_label:");
//     asm volatile ("li x31, 1;");
//     while(1);
// }
void _start() {
    // x1 (ra) should be 0 initially
    asm volatile ("li x1, 0;");
    
    // 1. Jump to 'func' and save the return address in x1
    // The address of the instruction AFTER this (the li x5, 0xBAD) 
    // should be stored in x1.
    asm volatile ("jal x1, func;");

    // This should be skipped if jump works
    asm volatile ("li x5, 0xBAD;"); 

    asm volatile ("func:");
    // If JAL worked, x1 now contains the address of the "li x5, 0xBAD" line.
    // We can verify x1 is not zero.
    asm volatile ("addi x31, x0, 1;"); 
    
    while(1);
}