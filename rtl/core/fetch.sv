// File: rtl/core/fetch.sv
// Brief: Fetch stage. Maintains program counter and fetches 32-bit instructions
// from instruction memory. Handles branch/jump targets from Execute stage
// and stall control from hazard unit.
module fetch (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset
    input  logic        Stall_F,                 // stall signal from hazard unit (hold PC)
    input  logic [63:0] PCTarget_E,              // branch/jump target address from Execute stage
    input  logic        PCSrc_E,                 // PC source: 0=sequential (PC+4), 1=branch/jump
    
    output logic [63:0] PC_F,                   // current program counter in Fetch stage
    output logic [31:0] Instr_F                 // 32-bit instruction fetched from memory
);

    // ============================================================
    // INTERNAL SIGNAL DECLARATIONS
    // ============================================================
    logic [63:0] pc_next;                       // next PC value (multiplexed: branch or sequential)
    logic [63:0] PCPlus4_F;                     // sequential next address (PC + 4)

    // ============================================================
    // 1. PC INCREMENT & BRANCH MULTIPLEXER
    // ============================================================
    // Sequential fetch: increment PC by 4 bytes (one 32-bit instruction)
    assign PCPlus4_F = PC_F + 64'd4;
    
    // Next PC selection:
    // If PCSrc_E = 1: branch/jump taken, use PCTarget_E from Execute stage
    // If PCSrc_E = 0: sequential fetch, use PC + 4
    assign pc_next   = (PCSrc_E) ? PCTarget_E : PCPlus4_F;

    // ============================================================
    // 2. PROGRAM COUNTER REGISTER
    // ============================================================
    // Holds current PC; updates on clock edge if not stalled (en = !Stall_F)
    // When Stall_F = 1, PC is held constant (for load-use hazard delays)
    pc pcreg (
        .clk(clk),                              // system clock
        .rst(rst),                              // synchronous reset (PC -> 0)
        .en(!Stall_F),                          // enable: update PC unless stalling
        .PCNext(pc_next),                       // next PC value (from multiplexer above)
        .PC(PC_F)                               // current PC output
    );

    // ============================================================
    // 3. INSTRUCTION MEMORY FETCH
    // ============================================================
    // Reads 32-bit instruction from instruction memory using current PC as address
    // This is a read-only combinational lookup (fetch happens every cycle)
    instruction imem (
        .A(PC_F),                               // instruction memory address (PC)
        .RD(Instr_F)                            // 32-bit instruction output
    );

endmodule