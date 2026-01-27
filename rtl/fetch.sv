module fetch (
    input  logic        clk,
    input  logic        rst,
    input  logic [63:0] PCTarget_E, // Branch target from Execute
    input  logic        PCSrc_E,    // Branch selection from Execute
    output logic [63:0] PC_D,       
    output logic [31:0] Instr_D     
);

    logic [63:0] PC_F;
    logic [31:0] Instr_F;
    logic [63:0] pc_next;
    logic [63:0] PCPlus4_F;

    // 1. Next PC Logic
    assign PCPlus4_F = PC_F + 64'd4;
    assign pc_next   = (PCSrc_E) ? PCTarget_E : PCPlus4_F;

    // 2. PC Register instantiation
    pc pcreg (
        .clk(clk),
        .rst(rst),
        .PCNext(pc_next), 
        .PC(PC_F)
    );

    // 3. Instruction Memory instantiation
    Instruction imem (
        .A(PC_F),
        .RD(Instr_F)
    );

    // 4. IF/ID Pipeline Register instantiation
    FD_pipeline reg_if_id (
        .clk(clk),
        .rst(rst),
        .PC_F(PC_F),
        .Instr_F(Instr_F),
        .PC_D(PC_D),
        .Instr_D(Instr_D)
    );

endmodule