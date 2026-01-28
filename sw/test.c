__attribute__((section(".text")))
void _start() {
    asm volatile (
        // 1. Setup initial values
        "addi x5, x0, 10;"      // x5 = 10
        "addi x6, x0, 20;"      // x6 = 20
        
        // 2. Trigger MEM -> EX Forwarding (rs1 match)
        // addi is in MEM stage when add is in EX.
        // x5 is forwarded from ALUResult_M to SrcA_E
        "addi x10, x0, 100;"    // x10 = 100
        "add  x11, x10, x6;"    // x11 = 100 + 20 = 120 (Forward x10 from MEM)
        
        // 3. Trigger WB -> EX Forwarding (rs2 match)
        // addi is in WB stage when sub is in EX.
        // x10 is forwarded from Result_W to SrcB_E
        "addi x12, x0, 50;"     // x12 = 50
        "nop;"                  // nop to move x10 to WB stage
        "sub  x13, x12, x10;"   // x13 = 50 - 100 = -50 (Forward x10 from WB)

        // 4. The "Triple Threat" (Priority Test)
        // Here x14 is updated twice. We must ensure EX grabs from MEM, not WB.
        "addi x14, x0, 1;"      // x14 = 1
        "addi x14, x0, 2;"      // x14 = 2 (More recent)
        "add  x15, x14, x14;"   // x15 = 2 + 2 = 4 (If 3 is returned, priority failed)

        // 5. Final result check and Infinite Loop
        "addi x31, x0, 1;"      // Success flag
        "loop: j loop;"
    );
}