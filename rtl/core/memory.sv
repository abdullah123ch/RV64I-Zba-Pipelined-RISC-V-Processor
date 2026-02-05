// File: rtl/core/memory.sv
// Brief: Memory stage. Performs load and store operations to/from data memory.
// Handles memory address alignment and read/write operations based on load/store control.
module memory (
    input  logic        clk,                     // system clock (for synchronized memory writes)
    
    // Data Inputs from EX/MEM (EM_pipeline) Register
    input  logic [63:0] ALUResult_M,             // address computed in Execute (for load/store)
    input  logic [63:0] WriteData_M,             // data to write to memory (from rs2 register)
    
    // Control Inputs from EX/MEM (EM_pipeline) Register
    input  logic        MemWrite_M,              // memory write enable (1=store, 0=load)
    
    // Outputs to MEM/WB (MW_pipeline) Register
    output logic [63:0] ReadData_M               // data read from memory (for load operations)
);

    // ============================================================
    // DATA MEMORY INSTANTIATION
    // ============================================================
    // Performs synchronous write on rising clock when MemWrite_M=1
    // Performs asynchronous read on every cycle (combinational)
    // Address bus (A) uses lower bits of ALUResult_M for byte addressing
    
    data data_mem (
        .clk(clk),                              // system clock (controls synchronous write)
        .WE(MemWrite_M),                        // write enable: 1=store operation, 0=load operation
        .A(ALUResult_M),                        // memory address (computed address from ALU result)
        .WD(WriteData_M),                       // write data (value from rs2 register for stores)
        .RD(ReadData_M)                         // read data (output for load operations)
    );

endmodule