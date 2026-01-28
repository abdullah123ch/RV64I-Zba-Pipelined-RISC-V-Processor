void __attribute__((naked)) _start() {
    asm volatile (
        "addi x5, x0, 10;"
        "addi x6, x0, 10;"
        "beq  x5, x6, jump_target;" // Should jump
        "addi x10, x0, 404;"        // This might execute due to delay! (Shadow 1)
        "addi x10, x0, 505;"        // This might execute due to delay! (Shadow 2)

        "jump_target:"
        "nop;"
        "nop;"
        "addi x10, x0, 100;"        // Success code
        "loop: j loop;" 
    );
}