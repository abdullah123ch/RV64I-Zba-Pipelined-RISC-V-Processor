module hazard_unit (
    // Inputs from Execute Stage
    input  logic [4:0] Rs1_E,
    input  logic [4:0] Rs2_E,
    input  logic [4:0] Rd_E,
    input  logic [1:0] ResultSrc_E,
    input  logic       PCSrc_E,

    // Inputs from Decode Stage
    input  logic [4:0] Rs1_D,
    input  logic [4:0] Rs2_D,

    // Inputs from Memory Stage
    input  logic [4:0] Rd_M,
    input  logic       RegWrite_M,
    
    // Inputs from Writeback Stage
    input  logic [4:0] Rd_W,
    input  logic       RegWrite_W,
    
    // Outputs to Execute Stage Muxes
    output logic [1:0] ForwardA_E,
    output logic [1:0] ForwardB_E,

    // Control Signals
    output logic       StallF, StallD, FlushE
);
    logic lwStall;

    // Forwarding Logic for Operand A
    always_comb begin
        if (((Rs1_E == Rd_M) && RegWrite_M) && (Rs1_E != 5'b0))
            ForwardA_E = 2'b10; // Priority: Memory Stage
        else if (((Rs1_E == Rd_W) && RegWrite_W) && (Rs1_E != 5'b0))
            ForwardA_E = 2'b01; // Writeback Stage
        else
            ForwardA_E = 2'b00; // No Forwarding 
    end

    // Forwarding Logic for Operand B
    always_comb begin
        if (((Rs2_E == Rd_M) && RegWrite_M) && (Rs2_E != 5'b0))
            ForwardB_E = 2'b10; // Priority: Memory Stage
        else if (((Rs2_E == Rd_W) && RegWrite_W) && (Rs2_E != 5'b0))
            ForwardB_E = 2'b01; // Writeback Stage
        else
            ForwardB_E = 2'b00; // No Forwarding 
    end

    // --- Load-Use Stall ---
    // If instruction in Execute is a Load (ResultSrc_E[0] == 1)
    // AND it matches a source register in the Decode stage
    assign lwStall = (ResultSrc_E == 2'b01) && (Rd_E != 5'b0) && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E));
    
    assign StallF = lwStall;
    assign StallD = lwStall;

    // --- 3. Control Hazard: Flush on Branch/Jump ---
    // If we jump/stall, we must flush the stage to prevent wrong execution
    assign FlushE = lwStall | PCSrc_E;
endmodule