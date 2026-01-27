module fetch (
    input  logic        clk,
    input  logic        rst,
    input  logic        Flush_D,    // Clear IF/ID on branch
    input  logic        Stall_D,    // Stall IF/ID on hazard
    input  logic [63:0] PCTarget_E, // Branch target from Execute
    input  logic        PCSrc_E,    // Selection signal from Execute
    output logic [63:0] PC_D,       // PC for Decode stage
    output logic [31:0] Instr_D     // Instruction for Decode stage
);

    logic [63:0] PC_F;
    logic [31:0] Instr_F;
    logic [63:0] pc_next;
    logic [63:0] PCPlus4_F;

    // 1. PC Logic: 
    assign PCPlus4_F = PC_F + 64'd4;
    assign pc_next   = (PCSrc_E) ? PCTarget_E : PCPlus4_F;

    // 2. PC Register (Sequential)
    
    pc pcreg (
        .clk(clk),
        .rst(rst),
        .PCNext((!Stall_D) ? pc_next : PC_F), // stall check (!Stall_D) to keep PC from advancing
        .PC(PC_F)
    );

    // 3. Instruction Memory 
    instruction imem (
        .A(PC_F),
        .RD(Instr_F)
    );

    // 4. IF/ID Pipeline Register
    FD_pipeline reg_if_id (
        .clk(clk),
        .rst(rst),
        .clr(Flush_D),
        .en(!Stall_D), // Only update if not stalling
        .PC_F(PC_F),
        .Instr_F(Instr_F),
        .PC_D(PC_D),
        .Instr_D(Instr_D)
    );

endmodule