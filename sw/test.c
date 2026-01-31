__attribute__((section(".text")))
void _start() {
    asm volatile (
        "addi s1, x0, 9;"   // x9
        "addi s2, x0, 18;"  // x18
        "addi s3, x0, 19;"  // x19
        "addi s4, x0, 20;"  // x20
        "addi s5, x0, 21;"  // x21
        "li x31, 0x7FF;"
    );
}