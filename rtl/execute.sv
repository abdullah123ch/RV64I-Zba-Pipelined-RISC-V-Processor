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
    input  logic        is_jalr_E,    // <--- ADDED TO PORT LIST
    
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
    logic [63:0] SrcB_E;
    logic [63:0] Forwarded_RD2_E;
    logic        BranchTaken_E;
    logic [63:0] PC_Relative_Target;
    logic [63:0] JALR_Target;

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
    always_comb begin
        case (ForwardB_E)
            2'b00:   Forwarded_RD2_E = RD2_E;
            2'b01:   Forwarded_RD2_E = Result_W;
            2'b10:   Forwarded_RD2_E = ALUResult_M;
            default: Forwarded_RD2_E = RD2_E;
        endcase
    end

    // 3. ALU Operand B Selection Mux (ALUSrc)
    assign SrcB_E = (ALUSrc_E) ? ImmExt_E : Forwarded_RD2_E;

    // 4. Instantiate the ALU
    alu alu_inst (
        .SrcA(SrcA_E),
        .SrcB(SrcB_E),
        .ALUControl(ALUControl_E),
        .ALUResult(ALUResult_E),
        .Zero(Zero_E)
    );

    // 5. Branch/Jump Target Calculation
    // Using SrcA_E for JALR ensures we use the forwarded return address
    assign PC_Relative_Target = PC_E + ImmExt_E;
    assign JALR_Target        = SrcA_E + ImmExt_E;

    assign PCTarget_E = (is_jalr_E) ? JALR_Target : PC_Relative_Target;

    // 6. Robust Branch Decision Logic
    
    always_comb begin
        case (funct3_E)
            3'b000:  BranchTaken_E = Zero_E;            // BEQ
            3'b001:  BranchTaken_E = ~Zero_E;           // BNE
            3'b100:  BranchTaken_E = ALUResult_E[0];    // BLT
            3'b101:  BranchTaken_E = ~ALUResult_E[0];   // BGE
            3'b110:  BranchTaken_E = ALUResult_E[0];    // BLTU
            3'b111:  BranchTaken_E = ~ALUResult_E[0];   // BGEU
            default: BranchTaken_E = 1'b0;
        endcase
    end

    // Final PC Source selection
    assign PCSrc_E = Jump_E | (Branch_E & BranchTaken_E);

    // 7. Pass-through for Store instructions
    assign WriteData_E = Forwarded_RD2_E;

endmodule