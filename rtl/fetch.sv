// Fetch Stage Wrapper for RV64I-Zba
module fetch_stage (
    input  logic        clk,
    input  logic        rst,
    input  logic [63:0] PCTarget,    // External PC update 
    input  logic        PCWrite_F,  // Control signal to enable PC update
    output logic [63:0] PC,       // Current PC sent to ID stage
    output logic [31:0] Instr    // Fetched instruction sent to ID stage
);

    logic [63:0] pc_next;
    logic [63:0] PCPlus4;

    // 1. PC Update Logic 
    assign PCPlus4 = PC + 64'd4;
    assign pc_next  = (PCWrite_F) ? PCTarget : PCPlus4;

    // 2. Instantiate Program Counter (PC)
    pc pcreg (
        .clk(clk),
        .rst(rst),
        .PCNext(pc_next),
        .PC(PC)
    );

    // 3. Instantiate Instruction Memory
    instr_mem imem (
        .A(PC),
        .RD(Instr)
    );

endmodule