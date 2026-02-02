module writeback (
    // Data Inputs from MEM/WB Register
    input  logic [63:0] ALUResult_W,
    input  logic [63:0] ReadData_W,
    input  logic [63:0] PCPlus4_W,
    
    // Control Input from MEM/WB Register
    input  logic [1:0]  ResultSrc_W, // 00: ALU, 01: Memory, 10: PC+4
    
    // Final Output to be sent back to the Decode Stage
    output logic [63:0] Result_W
);
    
    // Standard RISC-V Result Mux
    assign Result_W = (ResultSrc_W == 2'b00) ? ALUResult_W :
                    (ResultSrc_W == 2'b01) ? ReadData_W  :
                    (ResultSrc_W == 2'b10) ? PCPlus4_W   : 64'b0; // This gives us RA


endmodule