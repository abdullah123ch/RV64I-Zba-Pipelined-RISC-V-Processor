__attribute__((section(".text")))
void _start() {
    asm volatile (
        "addi x5, x0, 15;"      // x5 = 15 (Tests ADDI)
        "addi x6, x0, 5;"       // x6 = 5  (Tests ADDI)
        
        // Test ADD with Forwarding
        "add x7, x5, x6;"       // x7 = 15 + 5 = 20
                                // Needs x6 forwarded from EX/MEM stage
        
        // Test SUB with Forwarding
        "sub x8, x7, x6;"       // x8 = 20 - 5 = 15
                                // Needs x7 forwarded from EX/MEM
                                // Needs x6 forwarded from MEM/WB
        
        // Final verification for the Testbench
        "addi x31, x8, 2032;"   // x31 = 15 + 2032 = 2047 (0x7FF)
                                // If x31 == 0x7FF, all math and hazards passed
        
        "loop: j loop;"         // End of program
    );
}