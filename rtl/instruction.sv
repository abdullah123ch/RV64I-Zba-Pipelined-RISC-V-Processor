// Read-Only Instruction Memory for RV64I
module instruction (
    input  logic [63:0] A,   // Address from the PC  
    output logic [31:0] RD   // Instruction for the Fetch stage
);

    // Memory array: 1024 x 32-bit
    logic [31:0] rom [1023:0]; 

    // 2-bit word aligned addressing to access 32-bit instructions
    assign RD = rom[A[11:2]]; 
    

endmodule