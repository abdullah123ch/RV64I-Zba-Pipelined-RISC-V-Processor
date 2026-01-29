module fetch (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic        Stall_F,
    input  logic [63:0] PCTarget_E, // Branch target from Execute
    input  logic        PCSrc_E,    // Branch selection from Execute
    output logic [63:0] PC_F,       // Current PC in Fetch
    output logic [31:0] Instr_F     // Raw instruction from Memory
);

    logic [63:0] pc_next;
    logic [63:0] PCPlus4_F;

    // 1. Next PC Logic
    assign PCPlus4_F = PC_F + 64'd4;
    assign pc_next   = (PCSrc_E) ? PCTarget_E : PCPlus4_F;

    // 2. PC Register instantiation
    pc pcreg (
        .clk(clk),
        .rst(rst),
        .en(!Stall_F),
        .PCNext(pc_next), 
        .PC(PC_F)
    );

    // 3. Instruction Memory instantiation
    instruction imem (
        .A(PC_F),
        .RD(Instr_F)
    );

endmodule