// File: rtl/mem/instruction.sv
// Brief: Instruction ROM/memory module for Fetch stage instruction fetch.
// Provides asynchronous read of 32-bit instructions indexed by program counter.
// Note: Instructions are hard-coded for simulation; replace with .mem/.hex
// file loading for synthesis or larger programs.

module instruction (
    input  logic [63:0] A,                      // instruction memory address (from PC)
    output logic [31:0] RD                      // 32-bit instruction output
);

    // ============================================================
    // INSTRUCTION MEMORY STORAGE
    // ============================================================
    // 1024 entries (4 KB when accounting for 4-byte instructions)
    // Each entry holds a 32-bit RISC-V instruction
    logic [31:0] rom [0:1023];

    // ============================================================
    // INITIALIZATION WITH HARD-CODED INSTRUCTIONS
    // ============================================================
    // Loads test instructions for simulation/verification
    // Example sequence:
    // - Load immediate 10 into x1
    // - Load immediate 5 into x2  
    // - Perform shifted add (Zba extension): x3 = x1*2 + x2 (sh1add)
    // - Infinite loop instruction
    
    initial begin
        rom[0] = 32'h00a00093;                  // ADDI x1, x0, 10   (x1 = 0 + 10 = 10)
        rom[1] = 32'h00500013;                  // ADDI x2, x0, 5    (x2 = 0 + 5 = 5)
        rom[2] = 32'h2020a1b3;                  // SH1ADD x3, x1, x2 (x3 = (x1 << 1) + x2 = 20 + 5 = 25) [Zba ext]
        rom[3] = 32'h00000063;                  // BEQ x0, x0, 0     (infinite loop)
    end

    // ============================================================
    // ASYNCHRONOUS READ (Combinational)
    // ============================================================
    // Performs immediate instruction fetch without clock dependency
    // Uses lower 10 bits of PC as word index (divide by 4 for byte address)
    // A[11:2] extracts bits [11:2] from the 64-bit address = 10-bit word index
    
    assign RD = rom[A[11:2]];                   // read from rom using PC bits [11:2] as index
endmodule