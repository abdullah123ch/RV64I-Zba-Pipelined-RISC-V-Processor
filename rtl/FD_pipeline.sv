// IF/ID Pipeline Register (Simple Pipelined Version)

module FD_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic [63:0] PC_F,     
    input  logic [31:0] Instr_F,  
    output logic [63:0] PC_D,     
    output logic [31:0] Instr_D   
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC_D    <= 64'b0;
            Instr_D <= 32'b0;
        end else begin
            PC_D    <= PC_F;
            Instr_D <= Instr_F;
        end
    end

endmodule