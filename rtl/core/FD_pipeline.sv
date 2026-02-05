// File: rtl/core/FD_pipeline.sv
// Brief: Fetch->Decode pipeline register. Holds PC and 32-bit instruction
// between IF and ID stages with stall (en) and flush (clr) control signals.
module FD_pipeline (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset
    input  logic        en,                      // enable signal (connected to !Stall_D from hazard unit)
    input  logic        clr,                     // clear/flush signal (connected to Flush_D on branch)
    
    // Data from Fetch (F) stage
    input  logic [63:0] PC_F,                   // program counter value from Fetch
    input  logic [31:0] Instr_F,                // 32-bit instruction from instruction memory
    
    // Data to Decode (D) stage
    output logic [63:0] PC_D,                   // latched program counter
    output logic [31:0] Instr_D                 // latched instruction
);

    // Pipeline register with enable and clear controls
    // clr (flush) takes priority over en (stall) to squash bad instructions on branch misprediction
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clr) begin
            // Reset or flush: zero outputs to introduce NOP (illegal instruction) into Decode stage
            Instr_D <= 32'b0;       // set instruction to zero (NOP; typically decodes to no-ops)
            PC_D    <= 64'b0;       // PC -> 0
        end else if (en) begin
            // Normal operation: latch Fetch outputs when enable is asserted (no stall)
            // When en=0 (stalling), outputs hold previous values (latches are unchanged)
            Instr_D <= Instr_F;     // latch new instruction from Fetch
            PC_D    <= PC_F;        // latch new PC from Fetch
        end
        // If en=0 and clr=0, hold all outputs (implicit else with no update)
    end
endmodule