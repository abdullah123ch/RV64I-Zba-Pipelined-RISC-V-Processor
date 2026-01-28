module decode (
    input  logic        clk,
    input  logic        rst,
    
    // Inputs from IF/ID Register
    input  logic [31:0] Instr_D,
    input  logic [63:0] PC_D,
    
    // Inputs from Writeback Stage (Feedback)
    input  logic [63:0] Result_W,    // Data to be written to RF
    input  logic [4:0]  Rd_W,        // Destination register address
    input  logic        RegWrite_W,  // Register File Write Enable
    
    // Outputs to ID/EX Register
    output logic [63:0] RD1_D,       // Register operand 1
    output logic [63:0] RD2_D,       // Register operand 2
    output logic [63:0] ImmExt_D,    // Sign-extended immediate
    output logic [4:0]  Rd_D,        // Destination register address (Instr[11:7])
    output logic [63:0] PC_D_out,    // Pass-through PC
    
    // Control Signal Outputs to ID/EX Register
    output logic [1:0]  ResultSrc_D,
    output logic        MemWrite_D,
    output logic        ALUSrc_D,
    output logic        RegWrite_D,
    output logic [3:0]  ALUControl_D,
    output logic        Branch_D,     
    output logic        Jump_D
);

    // Internal wire for ImmSrc (doesn't leave the Decode stage)
    logic [2:0] ImmSrc_D;

    // 1. Destination Register Address
    assign Rd_D = Instr_D[11:7];
    assign PC_D_out = PC_D;

    // 2. Instantiate Register File
    register rf (
        .clk(clk),
        .rst(rst),
        .A1(Instr_D[19:15]), // rs1
        .A2(Instr_D[24:20]), // rs2
        .A3(Rd_W),           // from WB stage
        .WD3(Result_W),      // from WB stage
        .WE3(RegWrite_W),    // from WB stage
        .RD1(RD1_D),
        .RD2(RD2_D)
    );

    // 3. Instantiate Immediate Generator
    immediate ig (
        .Instr(Instr_D),
        .ImmSrc(ImmSrc_D),
        .ImmExt(ImmExt_D)
    );

    // 4. Instantiate Control Unit
    control_unit cu (
        .op(Instr_D[6:3]),        // Major Opcode
        .funct3(Instr_D[14:12]),
        .funct7_5(Instr_D[30]),   // Bit 30 for sub/sra
        .funct7_1(Instr_D[25]),   // Bit 25 for some Zba/M extensions
        .ResultSrc(ResultSrc_D),
        .MemWrite(MemWrite_D),
        .ALUSrc(ALUSrc_D),
        .ImmSrc(ImmSrc_D),
        .RegWrite(RegWrite_D),
        .ALUControl(ALUControl_D),
        .Branch(Branch_D),
        .Jump(Jump_D)
    );

endmodule