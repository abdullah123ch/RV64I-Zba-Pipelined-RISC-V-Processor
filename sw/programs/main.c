/*
 * File: sw/programs/main.c
 * Brief: Entry point for compiled C test program.
 * Runs user test code and returns status code (placed in x31 for verification).
 * 
 * Usage:
 *   - Define test logic here (e.g., arithmetic, memory access, branching)
 *   - Return a value: 0 for success, non-zero for failure
 *   - Testbench checks x31 for success marker (0x7FF)
 */

/*
 * ========================================================
 * MAIN FUNCTION
 * ========================================================
 * Entry point called by start.s bootloader.
 * 
 * Returns:
 *   - 0x7FF (2047): Success (expected by testbench)
 *   - other values: Test-specific status/errors
 * 
 * Note: Return value is transferred to x31 by start.s
 *       Testbench verifies x31 == 0x7FF for test pass
 */
int main(void) {
	/* ========================================================
	 * TODO: Insert test code here
	 * ========================================================
	 * Examples:
	 * - Arithmetic operations (ADD, SLT, Zba instructions)
	 * - Memory load/store sequences
	 * - Control flow (branches, jumps)
	 * - Register/memory state verification
	 * 
	 * Then return 0x7FF to signal success
	 */
	
	return 0;                                    // currently returns 0 (placeholder)
                                                // change to 0x7FF (2047) when test passes
}
