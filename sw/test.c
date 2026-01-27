// sw/test.c

// 1. Minimal Startup Logic
__attribute__((section(".text.init")))
void _start() {
    asm volatile ("li sp, 0x2000"); // Initialize stack pointer to end of 8KB mem
    main();
}

int main() {
    unsigned long rs1 = 10;
    unsigned long rs2 = 20;
    unsigned long rd;

    // Test Zba: sh1add rd, rs1, rs2
    // Calculation: (10 << 1) + 20 = 40 (0x28)
    asm volatile (
        ".insn r 0x33, 0x2, 0x10, %0, %1, %2" 
        : "=r" (rd) 
        : "r" (rs1), "r" (rs2)
    );

    // Loop forever to keep the pipeline active for observation
    while(1) {
        asm volatile ("nop");
    }
    return 0;
}