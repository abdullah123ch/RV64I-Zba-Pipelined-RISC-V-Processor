module core (
    input  logic        clk,
    input  logic        rst
);

    // --- Internal Wires: Fetch Stage (F) ---
    logic [63:0] PC_F;
    logic [31:0] Instr_F;

    // --- Internal Wires: Decode Stage (D) ---
    logic [63:0] PC_D;        // Fixed: semicolon instead of comma
    logic [31:0] Instr_D;
    logic [63:0] RD1_D, RD2_D, ImmExt_D; // Removed duplicate PC_D/Instr_D
    logic [4:0]  Rd_D;
    logic [1:0]  ResultSrc_D;
    logic        MemWrite_D, ALUSrc_D, RegWrite_D;
    logic [3:0]  ALUControl_D;
    logic        Branch_D, Jump_D;

    // --- Internal Wires: Execute Stage (E) ---
    logic [63:0] RD1_E, RD2_E, ImmExt_E, PC_E, ALUResult_E, WriteData_E, PCTarget_E;
    logic [4:0]  Rd_E;
    logic [1:0]  ResultSrc_E;
    logic        MemWrite_E, ALUSrc_E, RegWrite_E, Zero_E;
    logic [3:0]  ALUControl_E;
    logic        Branch_E, Jump_E, PCSrc_E;    

    // --- Internal Wires: Memory Stage (M) ---
    logic [63:0] ALUResult_M, WriteData_M, ReadData_M, PCPlus4_M;
    logic [4:0]  Rd_M;
    logic [1:0]  ResultSrc_M;
    logic        MemWrite_M, RegWrite_M;

    // --- Internal Wires: Writeback Stage (W) ---
    logic [63:0] ALUResult_W, ReadData_W, PCPlus4_W, Result_W;
    logic [4:0]  Rd_W;
    logic [1:0]  ResultSrc_W;
    logic        RegWrite_W;

    // --- Wires for Hazard Unit ---
    logic [4:0] Rs1_D, Rs2_D;      // From Decode
    logic [4:0] Rs1_E, Rs2_E;      // From ID/EX Pipeline
    logic [1:0] ForwardA_E, ForwardB_E; // From Hazard Unit to Execute
    logic       Stall_F, Stall_D, Flush_D, Flush_E;
// ============================================================
    // 1. FETCH STAGE
    // ============================================================
    fetch IF_STAGE (
        .clk(clk), .rst(rst), .Stall_F(Stall_F),
        .PCTarget_E(PCTarget_E), .PCSrc_E(PCSrc_E), 
        .PC_F(PC_F), .Instr_F(Instr_F)
    );

    FD_pipeline IF_ID_REG (
        .clk(clk), .rst(rst),
        .en(~Stall_D),
        .clr(Flush_D),
        .PC_F(PC_F), .Instr_F(Instr_F),
        .PC_D(PC_D), .Instr_D(Instr_D)
    );

    // ============================================================
    // 2. DECODE STAGE
    // ============================================================
    decode ID_STAGE (
        .clk(clk), .rst(rst),
        .Instr_D(Instr_D), .PC_D(PC_D),
        .Result_W(Result_W), .Rd_W(Rd_W), .RegWrite_W(RegWrite_W),
        .RD1_D(RD1_D), .RD2_D(RD2_D), .ImmExt_D(ImmExt_D), 
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D), // Pass register addresses out
        .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D), 
        .ALUSrc_D(ALUSrc_D), .RegWrite_D(RegWrite_D), .ALUControl_D(ALUControl_D),
        .Branch_D(Branch_D), .Jump_D(Jump_D)
    );

    DE_pipeline ID_EX_REG (
        .clk(clk), .rst(rst), .clr(Flush_E),
        .RD1_D(RD1_D), .RD2_D(RD2_D), .PC_D(PC_D), .ImmExt_D(ImmExt_D), 
        .Rd_D(Rd_D), .Rs1_D(Rs1_D), .Rs2_D(Rs2_D), // Pass addresses in
        .RegWrite_D(RegWrite_D), .ResultSrc_D(ResultSrc_D), .MemWrite_D(MemWrite_D),
        .ALUControl_D(ALUControl_D), .ALUSrc_D(ALUSrc_D), .Branch_D(Branch_D), .Jump_D(Jump_D),
        .RD1_E(RD1_E), .RD2_E(RD2_E), .PC_E(PC_E), .ImmExt_E(ImmExt_E), 
        .Rd_E(Rd_E), .Rs1_E(Rs1_E), .Rs2_E(Rs2_E), // Pass addresses out
        .RegWrite_E(RegWrite_E), .ResultSrc_E(ResultSrc_E), .MemWrite_E(MemWrite_E),
        .ALUControl_E(ALUControl_E), .ALUSrc_E(ALUSrc_E), .Branch_E(Branch_E), .Jump_E(Jump_E)
    );

    // ============================================================
    // 3. EXECUTE STAGE
    // ============================================================
    execute EX_STAGE (
        .RD1_E(RD1_E), .RD2_E(RD2_E), .ImmExt_E(ImmExt_E), .PC_E(PC_E),
        .ALUResult_M(ALUResult_M), .Result_W(Result_W), // Forwarded data inputs
        .ForwardA_E(ForwardA_E), .ForwardB_E(ForwardB_E),   // Mux select signals
        .ALUControl_E(ALUControl_E), .ALUSrc_E(ALUSrc_E), .Branch_E(Branch_E), .Jump_E(Jump_E),
        .ALUResult_E(ALUResult_E), .WriteData_E(WriteData_E), .PCTarget_E(PCTarget_E), .PCSrc_E(PCSrc_E), .Zero_E(Zero_E)
    );

    hazard_unit HAZARD_UNIT (
        .Rs1_E(Rs1_E), .Rs2_E(Rs2_E),
        .Rs1_D(Rs1_D), .Rs2_D(Rs2_D),
        .Rd_E(Rd_E), .ResultSrc_E(ResultSrc_E), .PCSrc_E(PCSrc_E),
        .Rd_M(Rd_M), .RegWrite_M(RegWrite_M),
        .Rd_W(Rd_W), .RegWrite_W(RegWrite_W),
        .ForwardA_E(ForwardA_E), .ForwardB_E(ForwardB_E),
        .Stall_F(Stall_F), .Stall_D(Stall_D), .Flush_E(Flush_E), .Flush_D(Flush_D)
    );

    EM_pipeline EX_MEM_REG (
        .clk(clk), .rst(rst),
        .ALUResult_E(ALUResult_E), .WriteData_E(WriteData_E), .Rd_E(Rd_E), .PCPlus4_E(PC_E + 4),
        .RegWrite_E(RegWrite_E), .ResultSrc_E(ResultSrc_E), .MemWrite_E(MemWrite_E),
        .ALUResult_M(ALUResult_M), .WriteData_M(WriteData_M), .Rd_M(Rd_M), .PCPlus4_M(PCPlus4_M),
        .RegWrite_M(RegWrite_M), .ResultSrc_M(ResultSrc_M), .MemWrite_M(MemWrite_M)
    );

    // ============================================================
    // 4. MEMORY STAGE
    // ============================================================
    memory MEM_STAGE (
        .clk(clk),
        .ALUResult_M(ALUResult_M), .WriteData_M(WriteData_M), .MemWrite_M(MemWrite_M),
        .ReadData_M(ReadData_M)
    );

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
    writeback WB_STAGE (
        .ALUResult_W(ALUResult_W), .ReadData_W(ReadData_W), .PCPlus4_W(PCPlus4_W),
        .ResultSrc_W(ResultSrc_W), .Result_W(Result_W)
    );

endmodule