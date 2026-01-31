module execute (
    // Data Inputs from ID/EX Register
    input  logic [63:0] RD1_E,
    input  logic [63:0] RD2_E,
    input  logic [63:0] ImmExt_E,
    input  logic [63:0] PC_E,
    
    // Forwarding Data Inputs
    input  logic [63:0] ALUResult_M, // Result from Memory stage
    input  logic [63:0] Result_W,    // Result from Writeback stage
    
    // Control Inputs from ID/EX Register
    input  logic [4:0]  ALUControl_E,
    input  logic        ALUSrc_E,     
    input  logic        Branch_E,
    input  logic        Jump_E,
    
    // Forwarding Control Signals (from Hazard Unit)
    input  logic [1:0]  ForwardA_E,    // 00: RD1_E, 01: Result_W, 10: ALUResult_M
    input  logic [1:0]  ForwardB_E,    // 00: RD2_E, 01: Result_W, 10: ALUResult_M
    
    // Outputs
    output logic [63:0] ALUResult_E,
    output logic [63:0] WriteData_E,  // This is the "Forwarded" RD2
    output logic [63:0] PCTarget_E,   
    output logic        PCSrc_E,      
    output logic        Zero_E        
);

    logic [63:0] SrcA_E;
    logic [63:0] SrcB_E;
    logic [63:0] Forwarded_RD2_E;

    // 1. Forwarding Mux for Operand A (SrcA)
    always_comb begin
        case (ForwardA_E)
            2'b00:   SrcA_E = RD1_E;
            2'b01:   SrcA_E = Result_W;
            2'b10:   SrcA_E = ALUResult_M;
            default: SrcA_E = RD1_E;
        endcase
    end

    // 2. Forwarding Mux for Operand B (RD2)
    // Note: We need the forwarded version of RD2 for both the ALU 
    // and for Store instructions (WriteData_E)
    always_comb begin
        case (ForwardB_E)
            2'b00:   Forwarded_RD2_E = RD2_E;
            2'b01:   Forwarded_RD2_E = Result_W;
            2'b10:   Forwarded_RD2_E = ALUResult_M;
            default: Forwarded_RD2_E = RD2_E;
        endcase
    end

    // 3. ALU Operand B Selection Mux (ALUSrc)
    // Chooses between the forwarded register data or the immediate
    assign SrcB_E = (ALUSrc_E) ? ImmExt_E : Forwarded_RD2_E;

    // 4. Instantiate the Zba-enabled ALU
    alu alu (
        .SrcA(SrcA_E),
        .SrcB(SrcB_E),
        .ALUControl(ALUControl_E),
        .ALUResult(ALUResult_E),
        .Zero(Zero_E)
    );

    // 5. Branch/Jump Target Calculation
    assign PCTarget_E = PC_E + ImmExt_E;

    // 6. Branch/Jump Decision Logic
    assign PCSrc_E = Jump_E | (Branch_E & Zero_E);

    // 7. Pass-through for Store instructions
    // IMPORTANT: Must use the forwarded data, otherwise you store old values!
    assign WriteData_E = Forwarded_RD2_E;

endmodule