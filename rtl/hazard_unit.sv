module hazard_unit (
    input  logic [4:0] Rs1_E, Rs2_E, Rd_E,
    input  logic [1:0] ResultSrc_E, 
    input  logic       PCSrc_E,
    input  logic [4:0] Rs1_D, Rs2_D,
    input  logic [4:0] Rd_M,
    input  logic       RegWrite_E,
    input  logic       RegWrite_M,
    input  logic [4:0] Rd_W,
    input  logic       RegWrite_W,
    input  logic       is_jalr_D,
    
    output logic [1:0] ForwardA_E, ForwardB_E,
    output logic       Stall_F, Stall_D, Flush_E, Flush_D, Flush_M
);
    logic lwStall;

    // --- 1. Forwarding Logic ---
    // Handles data hazards by grabbing results from M or W stages
    always_comb begin
        // Forward to Operand A (Crucial for JALR target)
        if      (((Rs1_E == Rd_M) && RegWrite_M) && (Rs1_E != 5'b0)) ForwardA_E = 2'b10;
        else if (((Rs1_E == Rd_W) && RegWrite_W) && (Rs1_E != 5'b0)) ForwardA_E = 2'b01;
        else                                                         ForwardA_E = 2'b00;

        // Forward to Operand B
        if      (((Rs2_E == Rd_M) && RegWrite_M) && (Rs2_E != 5'b0)) ForwardB_E = 2'b10;
        else if (((Rs2_E == Rd_W) && RegWrite_W) && (Rs2_E != 5'b0)) ForwardB_E = 2'b01;
        else                                                         ForwardB_E = 2'b00;
    end

    // --- 2. Load-Use Stall ---
    // ResultSrc_E[0] detects a Load (ResultSrc == 2'b01)
    // If JALR (in Decode) needs a register currently being loaded, we MUST stall.
    assign lwStall = (ResultSrc_E == 2'b01) && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E));
    assign jalrStall = is_jalr_D && (Rs1_D == Rd_E) && RegWrite_E;

// Update your Stall and Flush logic
    assign Stall_F = lwStall | jalrStall; 
    assign Stall_D = lwStall | jalrStall;

    // IMPORTANT: We must flush the Execute stage when we stall Decode, 
    // otherwise the 'BAD' instruction moves forward.
    assign Flush_E = PCSrc_E | lwStall | jalrStall; 

    assign Flush_D = PCSrc_E;
    assign Flush_M = 1'b0; // No flush in Memory stage for now
endmodule