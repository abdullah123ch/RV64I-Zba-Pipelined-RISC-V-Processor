module memory (
    input  logic        clk,
    
    // Data Inputs from EX/MEM Register
    input  logic [63:0] ALUResult_M,
    input  logic [63:0] WriteData_M, // rs2 value passed from EX
    
    // Control Inputs from EX/MEM Register
    input  logic        MemWrite_M,  // Enable signal for stores
    
    // Outputs to MEM/WB Register
    output logic [63:0] ReadData_M   // Data loaded from memory (for ld)
);

    // Instantiate Data Memory
    // A: Address, WD: Write Data, RD: Read Data
    data data_mem (
        .clk(clk),
        .WE(MemWrite_M),
        .A(ALUResult_M),
        .WD(WriteData_M),
        .RD(ReadData_M)
    );

endmodule