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
        if (rst) begin
            PC_D    <= 64'b0;
            Instr_D <= 32'h00000013; // NOP: addi x0, x0, 0
        end 
        else if (clr) begin
            // Clear takes priority over Enable to ensure 
            // mispredicted instructions are removed immediately.
            PC_D    <= 64'b0;
            Instr_D <= 32'h00000013; 
        end 
        else if (en) begin
            // Only update values if the stage is not stalled
            PC_D    <= PC_F;
            Instr_D <= Instr_F;
        end
    end

endmodule