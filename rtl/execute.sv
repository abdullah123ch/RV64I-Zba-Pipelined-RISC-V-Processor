module execute (
    // Data Inputs from ID/EX Register
    input  logic [63:0] RD1_E,
    input  logic [63:0] RD2_E,
    input  logic [63:0] ImmExt_E,
    input  logic [63:0] PC_E,
    
    // Control Inputs from ID/EX Register
    input  logic [3:0]  ALUControl_E,
    input  logic        ALUSrc_E,     // 0: register (RD2), 1: immediate (ImmExt)
    
    // Outputs to EX/MEM Register
    output logic [63:0] ALUResult_E,
    output logic [63:0] WriteData_E,  // Pass-through RD2_E for memory stores
    output logic [63:0] PCTarget_E,   // Branch/Jump target calculation
    output logic        Zero_E        // Zero flag for branch decisions
);

    logic [63:0] SrcB_E;

    // 1. ALU Operand B Selection Mux
    // If ALUSrc is 1, we use the immediate
    assign SrcB_E = (ALUSrc_E) ? ImmExt_E : RD2_E;

    // 2. Instantiate the Zba-enabled ALU
    alu alu (
        .SrcA(RD1_E),
        .SrcB(SrcB_E),
        .ALUControl(ALUControl_E),
        .ALUResult(ALUResult_E),
        .Zero(Zero_E)
    );

    // 3. Branch/Jump Target Calculation
    assign PCTarget_E = PC_E + ImmExt_E;

    // 4. Pass-through for Store instructions
    assign WriteData_E = RD2_E;

endmodule