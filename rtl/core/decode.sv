// File: rtl/core/decode.sv
// Brief: Decode stage. Decodes instruction fields, reads register file,
// generates sign-extended immediates, and produces control signals for
// downstream Execute, Memory and Writeback stages.
module decode (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset
    
    // Inputs from IF/ID Pipeline Register
    input  logic [31:0] Instr_D,                 // 32-bit instruction to decode
    input  logic [63:0] PC_D,                    // program counter (used for AUIPC/JAL/JALR)
    
    // Writeback Stage Feedback (for register file write-back)
    input  logic [63:0] Result_W,                // final result to write to register file
    input  logic [4:0]  Rd_W,                    // destination register index (writeback)
    input  logic        RegWrite_W,              // register write enable flag
    
    // Data Outputs to ID/EX Pipeline Register
    output logic [63:0] RD1_D, RD2_D,            // register file operands (rs1, rs2)
    output logic [63:0] ImmExt_D,                // sign/zero-extended immediate
    output logic [4:0]  Rd_D, Rs1_D, Rs2_D,    // register indices (rd, rs1, rs2)
    output logic [63:0] PC_D_out,                // program counter passthrough
    
    // Control Signal Outputs to ID/EX Pipeline Register
    output logic [1:0]  ResultSrc_D,             // writeback source: ALU/Memory/PC+4
    output logic        MemWrite_D,              // memory write enable
    output logic        ALUSrc_D,                // ALU operand B source: 0=register, 1=immediate
    output logic        RegWrite_D,              // register file write enable
    output logic [4:0]  ALUControl_D,            // ALU operation code
    output logic        Branch_D,                // branch instruction flag
    output logic        Jump_D,                  // jump (JAL/JALR) instruction flag
    output logic        is_jalr_D                // indicates JALR (register-indirect jump)
);

    // ============================================================
    // INTERNAL SIGNAL DECLARATIONS
    // ============================================================
    logic [2:0] ImmSrc_D;                       // immediate source selector (controls immediate generation)

    // ============================================================
    // 1. INSTRUCTION FIELD EXTRACTION
    // ============================================================
    // Extract register indices directly from instruction bits
    assign Rd_D = Instr_D[11:7];                // destination register (bits [11:7])
    assign Rs1_D = Instr_D[19:15];              // source register 1 (bits [19:15])
    assign Rs2_D = Instr_D[24:20];              // source register 2 (bits [24:20])
    assign PC_D_out = PC_D;                     // pass PC through to pipeline register

    // ============================================================
    // 2. REGISTER FILE READ
    // ============================================================
    // Reads two source registers (Rs1_D, Rs2_D) and writes back from Writeback stage
    // Write-back happens synchronously at clock edge (regulated by RegWrite_W)
    register rf (
        .clk(clk), .rst(rst),                   // clock and reset
        .A1(Rs1_D), .A2(Rs2_D),                 // source register addresses
        .A3(Rd_W),                              // writeback destination register address
        .WD3(Result_W),                         // writeback data from Writeback stage
        .WE3(RegWrite_W),                       // writeback enable signal
        .RD1(RD1_D), .RD2(RD2_D)                // register outputs to datapath
    );

    // ============================================================
    // 3. IMMEDIATE GENERATION (SIGN/ZERO EXTENSION)
    // ============================================================
    // Extracts and extends immediate field based on instruction type
    // ImmSrc controls which bits of the instruction are selected and how they're extended
    immediate ig (
        .Instr(Instr_D),                        // 32-bit instruction input
        .ImmSrc(ImmSrc_D),                      // selects immediate type (I/S/B/U/J-type)
        .ImmExt(ImmExt_D)                       // 64-bit sign/zero-extended immediate output
    );

    // ============================================================
    // 4. CONTROL UNIT (MAIN DECODER & ALU DECODER)
    // ============================================================
    // Decodes instruction to generate control signals for all pipeline stages
    // Inputs: opcode and funct fields from instruction
    // Outputs: control signals for ALU, memory, register file, and branch/jump
    control_unit cu (
        .op(Instr_D[6:0]),                      // primary opcode (bits [6:0])
        .funct3(Instr_D[14:12]),                // funct3 field (bits [14:12]) for ALU/branch operations
        .funct7_5(Instr_D[30]),                 // funct7[5] (bit [30]) distinguishes ADD/SUB
        .funct7_1(Instr_D[25]),                 // funct7[1] (bit [25]) used for Zba extension decoding
        .ResultSrc(ResultSrc_D),                // writeback source: 00=ALU, 01=Memory, 10=PC+4, others=TBD
        .MemWrite(MemWrite_D),                  // memory write enable for store instructions
        .ALUSrc(ALUSrc_D),                      // ALU operand B source: 0=register, 1=immediate
        .ImmSrc(ImmSrc_D),                      // immediate type selector for immediate generator
        .RegWrite(RegWrite_D),                  // register file write enable
        .ALUControl(ALUControl_D),              // 5-bit ALU operation code
        .Branch(Branch_D),                      // branch instruction flag (BEQ, BNE, BLT, etc.)
        .Jump(Jump_D),                          // jump instruction flag (JAL, JALR)
        .is_jalr(is_jalr_D)                     // JALR indicator (affects PC target calculation)

endmodule