module decode (
    input  logic        clk,
    input  logic        rst,
    
    // Inputs from IF/ID Register
    input  logic [31:0] Instr_D,
    input  logic [63:0] PC_D,
    
    // Inputs from Writeback Stage (Feedback)
    input  logic [63:0] Result_W,
    input  logic [4:0]  Rd_W,
    input  logic        RegWrite_W,
    
    // Outputs to ID/EX Register
    output logic [63:0] RD1_D, RD2_D, ImmExt_D,
    output logic [4:0]  Rd_D, Rs1_D, Rs2_D,
    output logic [63:0] PC_D_out,
    
    // Control Signal Outputs to ID/EX Register
    output logic [1:0]  ResultSrc_D,
    output logic        MemWrite_D,
    output logic        ALUSrc_D,
    output logic        RegWrite_D,
    output logic [4:0]  ALUControl_D,
    output logic        Branch_D,     
    output logic        Jump_D,
    output logic        is_jalr_D    // ADDED: Needed for Execute stage target mux
);

    // Internal wire for ImmSrc
    logic [2:0] ImmSrc_D;

    // 1. Wiring
    assign Rd_D = Instr_D[11:7];
    assign PC_D_out = PC_D;
    assign Rs1_D = Instr_D[19:15]; 
    assign Rs2_D = Instr_D[24:20];

    // 2. Register File
    register rf (
        .clk(clk), .rst(rst),
        .A1(Rs1_D), .A2(Rs2_D), .A3(Rd_W),
        .WD3(Result_W), .WE3(RegWrite_W),
        .RD1(RD1_D), .RD2(RD2_D)
    );

    // 3. Immediate Generator
    immediate ig (
        .Instr(Instr_D),
        .ImmSrc(ImmSrc_D),
        .ImmExt(ImmExt_D)
    );

    // 4. Control Unit
    control_unit cu (
        .op(Instr_D[6:2]),        // UPDATED: Now 5 bits to distinguish JALR/Branch
        .funct3(Instr_D[14:12]),
        .funct7_5(Instr_D[30]),
        .funct7_1(Instr_D[25]),
        .ResultSrc(ResultSrc_D),
        .MemWrite(MemWrite_D),
        .ALUSrc(ALUSrc_D),
        .ImmSrc(ImmSrc_D),
        .RegWrite(RegWrite_D),
        .ALUControl(ALUControl_D),
        .Branch(Branch_D),
        .Jump(Jump_D),
        .is_jalr(is_jalr_D)       // CONNECTED: Signal now flows to output
    );

endmodule