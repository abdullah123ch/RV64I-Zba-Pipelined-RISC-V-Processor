module execute (
    // Data Inputs from ID/EX Register
    input  logic [63:0] RD1_E,
    input  logic [63:0] RD2_E,
    input  logic [63:0] ImmExt_E,
    input  logic [63:0] PC_E,
    
    // Forwarding Data Inputs
    input  logic [63:0] ALUResult_M, 
    input  logic [63:0] Result_W,    
    
    // Control Inputs from ID/EX Register
    input  logic [4:0]  ALUControl_E,
    input  logic        ALUSrc_E,     
    input  logic        Branch_E,
    input  logic        Jump_E,
    input  logic [2:0]  funct3_E,     
    input  logic        is_jalr_E,    
    
    // Forwarding Control Signals (from Hazard Unit)
    input  logic [1:0]  ForwardA_E,    
    input  logic [1:0]  ForwardB_E,    
    
    // Outputs
    output logic [63:0] ALUResult_E,
    output logic [63:0] WriteData_E,  
    output logic [63:0] PCTarget_E,   
    output logic        PCSrc_E,      
    output logic        Zero_E        
);

    logic [63:0] SrcA_E;
    logic [63:0] Forwarded_RD2_E;
    logic [63:0] SrcB_E;
    logic        BranchTaken_E;
    
    // --- 1. Forwarding Muxes (Outside always_comb for Iverilog stability) ---
    assign SrcA_E = (ForwardA_E == 2'b10) ? ALUResult_M :
                    (ForwardA_E == 2'b01) ? Result_W    : RD1_E;

    assign Forwarded_RD2_E = (ForwardB_E == 2'b10) ? ALUResult_M :
                             (ForwardB_E == 2'b01) ? Result_W    : RD2_E;

    // --- 2. ALU Operand B Selection ---
    assign SrcB_E = (ALUSrc_E) ? ImmExt_E : Forwarded_RD2_E;

    // --- 3. ALU Instance ---
    alu alu_inst (
        .SrcA(SrcA_E),
        .SrcB(SrcB_E),
        .ALUControl(ALUControl_E),
        .ALUResult(ALUResult_E),
        .Zero(Zero_E)
    );

    // --- 4. Branch Logic (Pre-calculated to avoid 'sorry' error) ---
    // Extracting bit 0 outside any block is the safest way for Iverilog
    wire Less_E = ALUResult_E[0];

    

    always_comb begin
        case (funct3_E)
            3'b000:  BranchTaken_E = Zero_E;   // BEQ
            3'b001:  BranchTaken_E = ~Zero_E;  // BNE
            3'b100:  BranchTaken_E = Less_E;   // BLT
            3'b101:  BranchTaken_E = ~Less_E;  // BGE
            3'b110:  BranchTaken_E = Less_E;   // BLTU
            3'b111:  BranchTaken_E = ~Less_E;  // BGEU
            default: BranchTaken_E = 1'b0;
        endcase
    end

    // --- 5. Target Calculation & PC Control ---
    // PC_E + ImmExt_E (for JAL and Branches)
    // SrcA_E + ImmExt_E (for JALR)
    wire [63:0] PC_Relative_Target = PC_E + ImmExt_E;
    wire [63:0] JALR_Target_Raw    = SrcA_E + ImmExt_E;
    
    assign PCTarget_E = (is_jalr_E) ? {JALR_Target_Raw[63:1], 1'b0} : PC_Relative_Target;
    assign PCSrc_E    = Jump_E | (Branch_E & BranchTaken_E);

    // --- 6. Pass-throughs ---
    assign WriteData_E = Forwarded_RD2_E;

endmodule