__attribute__((section(".text")))
void _start() {
    asm volatile (
        "li x5, 500;"        // t0 = 500
        "li x6, 200;"        // t1 = 200
        
        // standard subtraction
        "sub x7, x5, x6;"    // t2 = 500 - 200 = 300 (0x12C)
        
        // subtraction resulting in a negative number
        "sub x8, x6, x5;"    // s0 = 200 - 500 = -300
        
        // check if subtracting from zero works (unary negation)
        "sub x9, x0, x7;"    // s1 = 0 - 300 = -300
        
        "li x31, 0x123;"
        "loop: j loop;"
    );
}