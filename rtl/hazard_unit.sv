module hazard_unit (
    // Inputs from Execute Stage
    input  logic [4:0] Rs1_E,
    input  logic [4:0] Rs2_E,
    
    // Inputs from Memory Stage
    input  logic [4:0] Rd_M,
    input  logic       RegWrite_M,
    
    // Inputs from Writeback Stage
    input  logic [4:0] Rd_W,
    input  logic       RegWrite_W,
    
    // Outputs to Execute Stage Muxes
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE
);

    // Forwarding Logic for Operand A
    always_comb begin
        if (((Rs1_E == Rd_M) && RegWrite_M) && (Rs1_E != 5'b0))
            ForwardAE = 2'b10; // Priority: Memory Stage
        else if (((Rs1_E == Rd_W) && RegWrite_W) && (Rs1_E != 5'b0))
            ForwardAE = 2'b01; // Writeback Stage
        else
            ForwardAE = 2'b00; // No Forwarding 
    end

    // Forwarding Logic for Operand B
    always_comb begin
        if (((Rs2_E == Rd_M) && RegWrite_M) && (Rs2_E != 5'b0))
            ForwardBE = 2'b10; // Priority: Memory Stage
        else if (((Rs2_E == Rd_W) && RegWrite_W) && (Rs2_E != 5'b0))
            ForwardBE = 2'b01; // Writeback Stage
        else
            ForwardBE = 2'b00; // No Forwarding 
    end

endmodule