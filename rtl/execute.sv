module execute (
    // Data Inputs from ID/EX Register
    input  logic [63:0] RD1_E,
    input  logic [63:0] RD2_E,
    input  logic [63:0] ImmExt_E,
    input  logic [63:0] PC_E,
    
    // Control Inputs from ID/EX Register
    input  logic [3:0]  ALUControl_E,
    input  logic        ALUSrc_E,     
    input  logic        Branch_E,     // NEW: From Control Unit via ID/EX
    input  logic        Jump_E,       // NEW: From Control Unit via ID/EX
    
    // Outputs
    output logic [63:0] ALUResult_E,
    output logic [63:0] WriteData_E,  
    output logic [63:0] PCTarget_E,   
    output logic        PCSrc_E,      // NEW: Final Branch/Jump decision
    output logic        Zero_E        
);

    logic [63:0] SrcB_E;

    // 1. ALU Operand B Selection Mux
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
    // For JALR, you would use RD1_E + ImmExt_E, but for JAL/Branch, it's PC-based:
    assign PCTarget_E = PC_E + ImmExt_E;

    // 4. Branch/Jump Decision Logic
    // PCSrc_E is high if we have an unconditional Jump OR a successful Branch
    assign PCSrc_E = Jump_E | (Branch_E & Zero_E);

    // 5. Pass-through for Store instructions
    assign WriteData_E = RD2_E;

endmodule