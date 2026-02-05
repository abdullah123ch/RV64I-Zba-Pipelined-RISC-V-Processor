// File: rtl/core/execute.sv
// Brief: Execute stage. Performs ALU operations, computes branch targets,
// applies data forwarding and selects PC source for branches/jumps.
module execute (
    // Data Inputs from ID/EX Pipeline Register
    input  logic [63:0] RD1_E,                  // register operand A (forwarded from regfile)
    input  logic [63:0] RD2_E,                  // register operand B (forwarded from regfile)
    input  logic [63:0] ImmExt_E,               // sign/zero-extended immediate from Decode
    input  logic [63:0] PC_E,                   // program counter latched in Execute (for AUIPC/JAL)
    input  logic [6:0]  op_E,                   // primary opcode (7-bit) to detect AUIPC operations
    
    // Data Forwarding Inputs (from later stages)
    input  logic [63:0] ALUResult_M,            // ALU result from Memory stage (for forwarding)
    input  logic [63:0] Result_W,               // final writeback result from Writeback stage
    
    // Control Inputs from ID/EX Pipeline Register
    input  logic [4:0]  ALUControl_E,           // 5-bit ALU operation code
    input  logic        ALUSrc_E,               // ALU operand B source: 0=register, 1=immediate
    input  logic        Branch_E,               // branch instruction flag
    input  logic        Jump_E,                 // jump (JAL/JALR) instruction flag
    input  logic [2:0]  funct3_E,               // funct3 field for branch condition evaluation
    input  logic        is_jalr_E,              // indicates JALR (register-indirect jump)
    
    // Forwarding Control Signals (from Hazard Unit)
    input  logic [1:0]  ForwardA_E,             // forwarding control for operand A: 2'b10=from M, 2'b01=from W
    input  logic [1:0]  ForwardB_E,             // forwarding control for operand B: 2'b10=from M, 2'b01=from W
    
    // Outputs
    output logic [63:0] ALUResult_E,            // 64-bit ALU result
    output logic [63:0] WriteData_E,            // data to be written to memory (store operand)
    output logic [63:0] PCTarget_E,             // computed target PC for branches/jumps
    output logic        PCSrc_E,                // PC source: 0=PC+4 (sequential), 1=branch/jump taken
    output logic        Zero_E                  // ALU zero flag (1 if ALUResult_E == 0)
);

    // Internal wires for datapath and forwarding
    logic [63:0] Forwarded_RD1_E;               // operand A after forwarding multiplexer
    logic [63:0] Forwarded_RD2_E;               // operand B after forwarding multiplexer
    logic [63:0] SrcA_E;                        // ALU operand A (AUIPC special case or forwarded RD1)
    logic [63:0] SrcB_E;                        // ALU operand B (immediate or forwarded RD2)
    logic        BranchTaken_E;                 // branch condition result (for BEQ/BNE/BLT/BGE)
    
    // ============================================================
    // 1. DATA FORWARDING MULTIPLEXERS
    // ============================================================
    // Forwarding multiplexer for operand A (RD1):
    // 2'b00 = no forward (use RD1_E from pipeline register)
    // 2'b01 = forward from Writeback stage (Result_W)
    // 2'b10 = forward from Memory stage (ALUResult_M)
    assign Forwarded_RD1_E = (ForwardA_E == 2'b10) ? ALUResult_M :
                             (ForwardA_E == 2'b01) ? Result_W    : RD1_E;

    // Forwarding multiplexer for operand B (RD2):
    // Same encoding as ForwardA_E
    assign Forwarded_RD2_E = (ForwardB_E == 2'b10) ? ALUResult_M :
                             (ForwardB_E == 2'b01) ? Result_W    : RD2_E;

    // ============================================================
    // 2. ALU OPERAND A SELECTION (CRITICAL FOR AUIPC/AUIPC)
    // ============================================================
    // AUIPC (opcode = 0010111) uses PC as the first operand
    // All other instructions use the forwarded register value (RD1)
    assign SrcA_E = (op_E == 7'b0010111) ? PC_E : Forwarded_RD1_E;

    // ============================================================
    // 3. ALU OPERAND B SELECTION
    // ============================================================
    // ALUSrc_E controls second ALU operand:
    // 1'b1 = immediate value (for I-type, S-type, B-type, loads)
    // 1'b0 = register value (for R-type, some other operations)
    assign SrcB_E = (ALUSrc_E) ? ImmExt_E : Forwarded_RD2_E;

    // ============================================================
    // 4. ALU INSTANTIATION
    // ============================================================
    // Computes ALU result and zero flag used by branch logic
    alu alu_inst (
        .SrcA(SrcA_E),                          // operand A (possibly from AUIPC path)
        .SrcB(SrcB_E),                          // operand B (reg or immediate)
        .ALUControl(ALUControl_E),              // 5-bit ALU control from control unit
        .ALUResult(ALUResult_E),                // 64-bit ALU computation result
        .Zero(Zero_E)                           // zero flag: 1 if result == 0
    );

    // ============================================================
    // 5. BRANCH CONDITION EVALUATION
    // ============================================================
    // The ALU also outputs a Less signal (MSB for SLT operations) for comparison
    wire Less_E = ALUResult_E[0];               // extract comparison bit (BLT/BGE/BLTU/BGEU)

    // Branch condition multiplexer based on funct3 field:
    // 000 = BEQ  (branch if equal, Zero_E = 1)
    // 001 = BNE  (branch if not equal, Zero_E = 0)
    // 100 = BLT  (branch if less than, Less_E = 1, signed)
    // 101 = BGE  (branch if greater/equal, Less_E = 0, signed)
    // 110 = BLTU (branch if less than, unsigned)
    // 111 = BGEU (branch if greater/equal, unsigned)
    always_comb begin
        case (funct3_E)
            3'b000:  BranchTaken_E = Zero_E;    // BEQ:  branch if zero flag set
            3'b001:  BranchTaken_E = ~Zero_E;   // BNE:  branch if zero flag clear
            3'b100:  BranchTaken_E = Less_E;    // BLT:  branch if less signal set
            3'b101:  BranchTaken_E = ~Less_E;   // BGE:  branch if less signal clear
            3'b110:  BranchTaken_E = Less_E;    // BLTU: branch if less (unsigned)
            3'b111:  BranchTaken_E = ~Less_E;   // BGEU: branch if not less (unsigned)
            default: BranchTaken_E = 1'b0;      // default: no branch
        endcase
    end

    // ============================================================
    // 6. PC TARGET CALCULATION & PC SOURCE CONTROL
    // ============================================================
    // PC target calculation path:
    // - For B-type (branches) and J-type (JAL): PC + immediate (PC-relative)
    // - For JALR: (RS1 + immediate) with LSB cleared to ensure word alignment
    
    // PC-relative target: PC + sign-extended immediate (used by branches and JAL)
    wire [63:0] PC_Relative_Target = PC_E + ImmExt_E;
    
    // JALR special case: target = (SrcA + immediate) with LSB forced to 0 (word alignment)
    // For other instructions (branches/JAL): use PC-relative calculation
    assign PCTarget_E = (is_jalr_E) ? {ALUResult_E[63:1], 1'b0} : PC_Relative_Target;
    
    // PC source control:
    // 1'b1 = take branch/jump (new PC = PCTarget_E)
    // 1'b0 = sequential fetch (PC+4 in Fetch stage)
    assign PCSrc_E    = Jump_E | (Branch_E & BranchTaken_E);

    // ============================================================
    // 7. MEMORY WRITE DATA PATH
    // ============================================================
    // Pass through the (possibly forwarded) RD2 value for store operations
    assign WriteData_E = Forwarded_RD2_E;

endmodule