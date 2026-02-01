module hazard_unit (
    input  logic [4:0] Rs1_E, Rs2_E, Rd_E,
    input  logic [1:0] ResultSrc_E, // ResultSrc_E == 2'b01 is LOAD
    input  logic       PCSrc_E,
    input  logic [4:0] Rs1_D, Rs2_D,
    input  logic [4:0] Rd_M,
    input  logic       RegWrite_M,
    input  logic [4:0] Rd_W,
    input  logic       RegWrite_W,
    
    output logic [1:0] ForwardA_E, ForwardB_E,
    output logic       Stall_F, Stall_D, Flush_E, Flush_D
);
    logic lwStall;

    // --- Forwarding Logic ---
    // This handles JALR if the previous instruction was R-Type/I-Type
    always_comb begin
        // Operand A (Handles JALR rs1 forwarding)
        if ((Rs1_E != 5'b0) && (Rs1_E == Rd_M) && RegWrite_M)      ForwardA_E = 2'b10;
        else if ((Rs1_E != 5'b0) && (Rs1_E == Rd_W) && RegWrite_W) ForwardA_E = 2'b01;
        else                                                      ForwardA_E = 2'b00;

        // Operand B
        if ((Rs2_E != 5'b0) && (Rs2_E == Rd_M) && RegWrite_M)      ForwardB_E = 2'b10;
        else if ((Rs2_E != 5'b0) && (Rs2_E == Rd_W) && RegWrite_W) ForwardB_E = 2'b01;
        else                                                      ForwardB_E = 2'b00;
    end

    // --- Data Hazard: Load-Use Stall ---
    // This triggers if a LOAD is in Execute (ResultSrc_E == 2'b01)
    // and the instruction in Decode (could be JALR, ADD, etc.) needs that data.
    assign lwStall = (ResultSrc_E == 2'b01) && ((Rs1_D == Rd_E) || (Rs2_D == Rd_E));

    assign Stall_F = lwStall; 
    assign Stall_D = lwStall;

    // --- Control Hazard: Flush ---
    // PCSrc_E is high when JAL, JALR, or a Taken Branch is in Execute.
    // We must kill the instructions in Fetch and Decode stages.
    assign Flush_D = PCSrc_E;
    assign Flush_E = lwStall | PCSrc_E;

endmodule