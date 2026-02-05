// File: rtl/core/pc.sv
// Brief: 64-bit Program Counter register. Maintains instruction fetch address.
// Supports synchronous reset and enable/disable control for stall handling.
module pc (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset (PC -> 0 on reset)
    input  logic        en,                      // enable signal: 1=update PC, 0=hold PC
    input  logic [63:0] PCNext,                 // next PC value (from multiplexer in Fetch)
    output logic [63:0] PC                      // current program counter value
);

    // ============================================================
    // PROGRAM COUNTER REGISTER
    // ============================================================
    // On reset: PC is forced to 0 (start of program)
    // When enabled: PC is updated with PCNext value (from Fetch logic)
    // When disabled (en=0): PC holds its current value (used during stall)
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 64'b0;                        // reset PC to 0 (program start address)
        end else if (en) begin
            PC <= PCNext;                       // update PC with next address on rising clock
        end
        // If en=0, PC holds its previous value (implicit else with no update)
    end

endmodule