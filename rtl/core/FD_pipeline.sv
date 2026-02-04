// IF/ID Pipeline Register 
module FD_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,   // Connected to !Stall_D
    input  logic        clr,  // Connected to Flush_D
    input  logic [63:0] PC_F,     
    input  logic [31:0] Instr_F,  
    output logic [63:0] PC_D,     
    output logic [31:0] Instr_D   
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || clr) begin     // clr (Flush_D) MUST be checked first!
            Instr_D <= 32'b0;     // Kill the instruction
            PC_D    <= 64'b0;
        end else if (en) begin    // Only update if NOT stalling
            Instr_D <= Instr_F;
            PC_D    <= PC_F;
        end
    end
endmodule