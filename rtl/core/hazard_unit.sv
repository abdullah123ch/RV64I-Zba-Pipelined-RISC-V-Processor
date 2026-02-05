// File: rtl/core/hazard_unit.sv
// Brief: Hazard detection and control unit. Detects data hazards (load-use,
// JALR register dependency) and control hazards (branch/jump). Generates
// forwarding controls, stall signals, and pipeline flush signals.
module hazard_unit (
    // Data operand and destination register signals from Execute stage
    input  logic [4:0] Rs1_E, Rs2_E, Rd_E,      // source and destination registers in Execute
    input  logic [1:0] ResultSrc_E,             // result source: 01 = memory load
    input  logic       PCSrc_E,                 // PC source: 1 = branch/jump taken
    
    // Data operand and destination register signals from Decode stage
    input  logic [4:0] Rs1_D, Rs2_D,            // source registers in Decode (for load-use hazard detection)
    
    // Register write signals and destination registers from Memory and Writeback stages
    input  logic [4:0] Rd_M,                    // destination register in Memory stage
    input  logic       RegWrite_E,              // register write enable in Execute stage
    input  logic       RegWrite_M,              // register write enable in Memory stage
    input  logic [4:0] Rd_W,                    // destination register in Writeback stage
    input  logic       RegWrite_W,              // register write enable in Writeback stage
    
    // Control signals from Decode stage
    input  logic       is_jalr_D,               // JALR instruction flag in Decode
    
    // Forwarding Control Outputs
    output logic [1:0] ForwardA_E, ForwardB_E,  // forwarding selectors for ALU operands A and B
                                                // 2'b00 = no forwarding, 2'b01 = from W, 2'b10 = from M
    
    // Pipeline Control Outputs
    output logic       Stall_F, Stall_D,        // stall Fetch and Decode stages (hold PC and pipeline regs)
    output logic       Flush_E, Flush_D, Flush_M // flush signals to clear pipeline registers on branch/jump
);
    logic lwStall;                              // load-use stall flag
    logic jalrStall;                            // JALR register dependency stall flag

    // ============================================================
    // 1. DATA FORWARDING LOGIC
    // ============================================================
    // Resolves read-after-write data hazards by forwarding results from
    // earlier pipeline stages (M or W) directly to ALU inputs in Execute stage
    
    // Forwarding multiplexer for Operand A (Rs1_E):
    // Priority: Memory stage (most recent) > Writeback stage > no forward
    // Does not forward to x0 (register 0, which is hardwired to 0)
    always_comb begin
        // Forward to Operand A (Rs1_E) - CRITICAL FOR JALR target calculation
        if      (((Rs1_E == Rd_M) && RegWrite_M) && (Rs1_E != 5'b0)) ForwardA_E = 2'b10; // Forward from M stage
        else if (((Rs1_E == Rd_W) && RegWrite_W) && (Rs1_E != 5'b0)) ForwardA_E = 2'b01; // Forward from W stage
        else                                                         ForwardA_E = 2'b00; // No forward

        // Forward to Operand B (Rs2_E) - for ALU operand B and store data
        if      (((Rs2_E == Rd_M) && RegWrite_M) && (Rs2_E != 5'b0)) ForwardB_E = 2'b10; // Forward from M stage
        else if (((Rs2_E == Rd_W) && RegWrite_W) && (Rs2_E != 5'b0)) ForwardB_E = 2'b01; // Forward from W stage
        else                                                         ForwardB_E = 2'b00; // No forward
    end

    // ============================================================
    // 2. LOAD-USE HAZARD DETECTION
    // ============================================================
    // Detects when a load instruction's result is used by the immediately following instruction
    // ResultSrc_E[0] == 1 indicates a load operation (ResultSrc == 2'b01)
    // If the next instruction reads from the load destination register, we stall one cycle
    assign lwStall = (ResultSrc_E == 2'b01) && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E));

    // ============================================================
    // 3. JALR REGISTER DEPENDENCY STALL
    // ============================================================
    // JALR uses the result of the previous instruction as its target address
    // If the previous instruction is a load to the same register, we must stall
    assign jalrStall = is_jalr_D && (Rs1_D == Rd_E) && RegWrite_E;

    // ============================================================
    // 4. PIPELINE STALL CONTROL
    // ============================================================
    // Stall Fetch and Decode stages on load-use or JALR hazards
    // When stalled, PC is held constant and pipeline registers don't update
    assign Stall_F = lwStall | jalrStall;       // stall Fetch stage
    assign Stall_D = lwStall | jalrStall;       // stall Decode stage

    // ============================================================
    // 5. PIPELINE FLUSH CONTROL (CONTROL HAZARDS)
    // ============================================================
    // Flush Execute stage when:
    // 1. Branch/jump is taken (PCSrc_E = 1) - discard Execute instruction
    // 2. Load-use stall occurs - don't propagate stalled instruction to Memory
    // 3. JALR dependency stall occurs
    
    assign Flush_E = PCSrc_E | lwStall | jalrStall;  // flush Execute stage on branch/stall
    
    assign Flush_D = PCSrc_E;                       // flush Decode on branch/jump taken
    assign Flush_M = 1'b0;                          // no flush in Memory stage (not needed for now)
endmodule