// IF/ID Pipeline Register

module FD_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic        clr,      // Flush signal for branch misprediction
    input  logic        en,       // Enable signal for stalling
    input  logic [63:0] PC_F,     // PC from Fetch stage
    input  logic [31:0] Instr_F,  // Instruction from Fetch stage
    output logic [63:0] PC_D,     // PC passed to Decode stage
    output logic [31:0] Instr_D   // Instruction passed to Decode stage
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || clr) begin
            PC_D    <= 64'b0;
            Instr_D <= 32'b0;
        end else if (en) begin
            PC_D    <= PC_F;
            Instr_D <= Instr_F;
        end
    end

endmodule