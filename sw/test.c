__attribute__((section(".text")))
void _start() {
    asm volatile (
        "addi x5, x0, 10;"      
        "addi x6, x0, 10;"      
        
        // Data Hazard + Branch Test
        "beq  x5, x6, jump_target;" // Should jump. Decision made in EX.
        "addi x10, x0, 0x111;"      // SHADOW 1: Should be Flushed by FlushE
        "addi x11, x0, 0x222;"      // SHADOW 2: Will LEAK (execute) because FlushD is missing
        
        "jump_target:"
        "addi x31, x0, 0x7FF;"       // Success marker 
        "loop: j loop;"
    );
}