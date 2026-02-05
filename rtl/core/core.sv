// File: rtl/core/core.sv
// Brief: Top-level pipelined RV64I core integration. Instantiates pipeline
// stages: fetch, decode, execute, memory, writeback and hazard unit.
// Ports: clock, reset and simple `led_output` for board/debug visibility.
module core (
    input  logic        clk,                    // system clock
    input  logic        rst,                    // synchronous reset
    output logic [7:0]  led_output              // low-cost debug LED output
);

    // ============================================================
    // INTERNAL SIGNAL DECLARATIONS BY PIPELINE STAGE
    // ============================================================

    // --- Internal Wires: Fetch Stage (F) ---
    logic [63:0] PC_F;            // program counter value in Fetch stage
    logic [31:0] Instr_F;         // 32-bit instruction fetched from instruction memory

    // --- Internal Wires: Decode/ID Stage (D) ---
    logic [63:0] PC_D;            // PC latched from Fetch into Decode stage
    logic [31:0] Instr_D;         // instruction latched from Fetch into Decode stage
    logic [63:0] RD1_D, RD2_D;    // register file read data: operand A (rs1) and operand B (rs2)
    logic [63:0] ImmExt_D;        // immediate value after sign/zero-extension based on instruction type
    logic [4:0]  Rd_D, Rs1_D, Rs2_D; // register indices: destination (rd), source1 (rs1), source2 (rs2)
    logic [1:0]  ResultSrc_D;     // writeback source selector at Decode (selects ALU/Memory/PC+4/PC)
    logic        MemWrite_D;      // memory write enable signal produced by control unit in Decode
    logic        ALUSrc_D;        // ALU operand B source select: 1'b1=immediate, 1'b0=register (from Decode)
    logic        RegWrite_D;      // register file write enable control signal at Decode
    logic [4:0]  ALUControl_D;    // ALU operation code (5-bit) from control unit at Decode
    logic        Branch_D, Jump_D; // branch/jump instruction indicators from control unit
    logic        is_jalr_D;       // indicates JALR instruction (indirect jump; affects PC target calculation)
    logic [6:0]  op_D;            // primary opcode extracted from Instr_D[6:0] for pipeline consistency

    // --- Internal Wires: Execute/EX Stage (E) ---
    logic [63:0] RD1_E, RD2_E;    // register operands latched from Decode, potentially with forwarding applied
    logic [63:0] ImmExt_E;        // latched immediate value for Execute stage
    logic [63:0] PC_E;            // latched PC for Execute stage (used by AUIPC and JAL target calculations)
    logic [63:0] ALUResult_E;     // 64-bit result computed by ALU in Execute stage
    logic [63:0] WriteData_E;     // value to be written to memory in store instructions (RD2_E after forwarding)
    logic [63:0] PCTarget_E;      // computed PC target address for branches/jumps (fed back to Fetch)
    logic [4:0]  Rd_E, Rs1_E, Rs2_E; // register indices (rd, rs1, rs2) latched into Execute
    logic [2:0]  funct3_E;        // funct3 field (bits [14:12]) passed to Execute for branch condition evaluation
    logic [1:0]  ResultSrc_E;     // writeback source selector propagated to Execute stage path
    logic        MemWrite_E;      // memory write enable signal propagated from Decode through Execute
    logic        ALUSrc_E;        // ALU operand B source selector propagated to Execute stage
    logic        RegWrite_E;      // register write enable signal propagated to Execute and beyond
    logic        Zero_E;          // ALU zero flag (1 if ALUResult_E == 0); used for branch condition evaluation
    logic [4:0]  ALUControl_E;    // 5-bit ALU control code propagated to Execute stage
    logic        Branch_E, Jump_E; // branch/jump control signals propagated to Execute (for PCTarget calculation)
    logic        PCSrc_E;         // PC source selector: 1'b1 = branch/jump taken, 1'b0 = sequential (PC+4)
    logic        is_jalr_E;       // JALR indicator latched in Execute (indicates PC target = RD1 + immediate)
    logic [6:0]  op_E;            // opcode latched into Execute stage (used for AUIPC and other special cases)

    // --- Internal Wires: Memory/M Stage (M) ---
    logic [63:0] ALUResult_M;     // ALU result latched into Memory stage (used as memory address for loads/stores)
    logic [63:0] WriteData_M;     // store data latched into Memory stage (value to write to memory)
    logic [63:0] ReadData_M;      // data read back from data memory (in load operations)
    logic [63:0] PCPlus4_M;       // PC+4 value latched for writeback (used by JAL/JALR to save return address)
    logic [4:0]  Rd_M;            // destination register index latched into Memory stage
    logic [1:0]  ResultSrc_M;     // writeback source selector latched into Memory stage
    logic        MemWrite_M;      // memory write enable propagated to Memory stage
    logic        RegWrite_M;      // register write enable propagated to Memory stage

    // --- Internal Wires: Writeback/WB Stage (W) ---
    logic [63:0] ALUResult_W;     // ALU result latched into Writeback stage
    logic [63:0] ReadData_W;      // memory read data latched into Writeback stage
    logic [63:0] PCPlus4_W;       // PC+4 latched into Writeback stage (for JAL/JALR return address)
    logic [63:0] Result_W;        // final multiplexed result selected for writeback to register file
    logic [4:0]  Rd_W;            // destination register index in Writeback stage (selects target register for write)
    logic [1:0]  ResultSrc_W;     // writeback source selector in Writeback stage
    logic        RegWrite_W;      // final write enable signal to register file (from Writeback stage)

    // --- Control & Hazard Wires ---
    logic [1:0] ForwardA_E, ForwardB_E; // forwarding control signals: 2'b00=no forward, 2'b01=from M, 2'b10=from W
    logic       Stall_F, Stall_D;        // pipeline stall signals for Fetch and Decode stages (on load-use hazards)
    logic       Flush_D, Flush_E, Flush_M; // pipeline flush signals (on branch misprediction or exception)

    // ============================================================
    // 1. FETCH STAGE
    // ============================================================
    // Fetch stage: holds PC, fetches instruction from instruction memory
    fetch IF_STAGE (
        .clk(clk), .rst(rst), .Stall_F(Stall_F),         // control inputs
        .PCTarget_E(PCTarget_E), .PCSrc_E(PCSrc_E),      // branch/jump inputs from EX
        .PC_F(PC_F), .Instr_F(Instr_F)                  // outputs to IF/ID register
    );

    // IF/ID pipeline register: latches PC and instruction from IF stage
    FD_pipeline IF_ID_REG (
        .clk(clk), .rst(rst),
        .en(~Stall_D), .clr(Flush_D),   // enable/clear controlled by hazard unit
        .PC_F(PC_F), .Instr_F(Instr_F),
        .PC_D(PC_D), .Instr_D(Instr_D)
    );

    // ============================================================
    // 2. DECODE STAGE
    // ============================================================
    // Decode stage: reads register file, generates immediate and control signals
    decode ID_STAGE (
        .clk(clk), .rst(rst),
        .Instr_D(Instr_D), .PC_D(PC_D),
        .Result_W(Result_W), .Rd_W(Rd_W), .RegWrite_W(RegWrite_W),
        .RD1_D(RD1_D), .RD2_D(RD2_D), .ImmExt_D(ImmExt_D),
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D),
        .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D),
        .ALUSrc_D(ALUSrc_D), .RegWrite_D(RegWrite_D), .ALUControl_D(ALUControl_D),
        .Branch_D(Branch_D), .Jump_D(Jump_D), .is_jalr_D(is_jalr_D)
    );

    assign op_D = Instr_D[6:0];

    // ID/EX pipeline register: transfers decoded operands and control to EX
    DE_pipeline ID_EX_REG (
        .clk(clk),
        .rst(rst),
        .clr(Flush_E),       // Clear on branch/mispredict or flush

        // Data Inputs (from decode)
        .RD1_D(RD1_D), .RD2_D(RD2_D), .PC_D(PC_D), .ImmExt_D(ImmExt_D),
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D), .op_D(op_D),

        // Control Inputs (from control unit via decode)
        .RegWrite_D(RegWrite_D),
        .ResultSrc_D(ResultSrc_D),
        .MemWrite_D(MemWrite_D),
        .ALUControl_D(ALUControl_D),
        .ALUSrc_D(ALUSrc_D),
        .Branch_D(Branch_D),
        .Jump_D(Jump_D),
        .is_jalr_D(is_jalr_D),
        .funct3_D(Instr_D[14:12]),

        // Data Outputs (to execute)
        .RD1_E(RD1_E), .RD2_E(RD2_E), .PC_E(PC_E), .ImmExt_E(ImmExt_E),
        .Rd_E(Rd_E), .Rs1_E(Rs1_E), .Rs2_E(Rs2_E), .op_E(op_E),

        // Control Outputs (to execute)
        .RegWrite_E(RegWrite_E),
        .ResultSrc_E(ResultSrc_E),
        .MemWrite_E(MemWrite_E),
        .ALUControl_E(ALUControl_E),
        .ALUSrc_E(ALUSrc_E),
        .Branch_E(Branch_E),
        .Jump_E(Jump_E),
        .is_jalr_E(is_jalr_E),
        .funct3_E(funct3_E)
    );

    // ============================================================
    // 3. EXECUTE STAGE
    // ============================================================
    // Execute stage: performs ALU ops, computes branch target and PC selection
    execute EX_STAGE (
        .RD1_E(RD1_E), .RD2_E(RD2_E), .ImmExt_E(ImmExt_E), .PC_E(PC_E),
        .ALUResult_M(ALUResult_M), .Result_W(Result_W),
        .ALUControl_E(ALUControl_E), .ALUSrc_E(ALUSrc_E),
        .Branch_E(Branch_E), .Jump_E(Jump_E), .funct3_E(funct3_E),
        .ForwardA_E(ForwardA_E), .ForwardB_E(ForwardB_E),
        .ALUResult_E(ALUResult_E), .WriteData_E(WriteData_E),
        .PCTarget_E(PCTarget_E), .PCSrc_E(PCSrc_E), .Zero_E(Zero_E), .is_jalr_E(is_jalr_E), .op_E(op_E)
    );

    // Hazard unit: computes forwarding, stalls and flushes to handle data/control hazards
    hazard_unit HAZARD_UNIT (
        .Rs1_E(Rs1_E), .Rs2_E(Rs2_E), .Rd_E(Rd_E),
        .ResultSrc_E(ResultSrc_E), .is_jalr_D(is_jalr_D), .PCSrc_E(PCSrc_E),
        .Rs1_D(Rs1_D), .Rs2_D(Rs2_D),
        .Rd_M(Rd_M), .RegWrite_M(RegWrite_M), .RegWrite_E(RegWrite_E),
        .Rd_W(Rd_W), .RegWrite_W(RegWrite_W),
        .ForwardA_E(ForwardA_E), .ForwardB_E(ForwardB_E),
        .Stall_F(Stall_F), .Stall_D(Stall_D), .Flush_E(Flush_E), .Flush_D(Flush_D), .Flush_M(Flush_M)
    );

    // EX/MEM pipeline register: passes results from EX to Memory stage
    EM_pipeline EX_MEM_REG (
        .clk(clk), .rst(rst), .clr(Flush_M),
        .ALUResult_E(ALUResult_E), .WriteData_E(WriteData_E), .Rd_E(Rd_E), .PCPlus4_E(PC_E + 4),
        .RegWrite_E(RegWrite_E), .ResultSrc_E(ResultSrc_E), .MemWrite_E(MemWrite_E),
        .ALUResult_M(ALUResult_M), .WriteData_M(WriteData_M), .Rd_M(Rd_M), .PCPlus4_M(PCPlus4_M),
        .RegWrite_M(RegWrite_M), .ResultSrc_M(ResultSrc_M), .MemWrite_M(MemWrite_M)
    );

    // ============================================================
    // 4. MEMORY STAGE
    // ============================================================
    // Memory stage: interfaces with `data` memory module for loads/stores
    memory MEM_STAGE (
        .clk(clk),
        .ALUResult_M(ALUResult_M), .WriteData_M(WriteData_M), .MemWrite_M(MemWrite_M),
        .ReadData_M(ReadData_M)
    );

    // MEM/WB pipeline register: latches memory results for writeback
    MW_pipeline MEM_WB_REG (
        .clk(clk), .rst(rst),
        .ALUResult_M(ALUResult_M), .ReadData_M(ReadData_M), .Rd_M(Rd_M), .PCPlus4_M(PCPlus4_M),
        .RegWrite_M(RegWrite_M), .ResultSrc_M(ResultSrc_M),
        .ALUResult_W(ALUResult_W), .ReadData_W(ReadData_W), .Rd_W(Rd_W), .PCPlus4_W(PCPlus4_W),
        .RegWrite_W(RegWrite_W), .ResultSrc_W(ResultSrc_W)
    );

    // ============================================================
    // 5. WRITEBACK STAGE
    // ============================================================
    // Writeback stage: selects final value to write to register file
    writeback WB_STAGE (
        .ALUResult_W(ALUResult_W), .ReadData_W(ReadData_W), .PCPlus4_W(PCPlus4_W),
        .ResultSrc_W(ResultSrc_W), .Result_W(Result_W)
    );

    // Expose low byte of result on LEDs for quick visibility in simulation/board
    assign led_output = Result_W[7:0];

endmodule