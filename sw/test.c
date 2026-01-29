// sw/test.c
__attribute__((section(".text")))
void _start() {
    asm volatile (
        "addi x1, x0, 10;"     // 0x00: Load-use source
        "ld   x2, 0(x1);"      // 0x04: Trigger Stall on next cycle
        "add  x3, x2, x1;"     // 0x08: This should see PC_F freeze for 1 cycle
        "beq  x0, x0, target;" // 0x0C: Trigger Flush on next cycle
        "addi x4, x0, 99;"     // 0x10: This should be converted to a NOP (Flush)
        "target:"
        "addi x5, x0, 50;"     // 0x14: Branch target
        "loop: j loop;"
    );
}