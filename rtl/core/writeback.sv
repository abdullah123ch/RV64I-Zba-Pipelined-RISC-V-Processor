// File: rtl/core/writeback.sv
// Brief: Writeback stage. Selects final result to write back to register file
// from multiple sources (ALU, memory, or PC+4) based on ResultSrc control signal.
module writeback (
    // Data Inputs from MEM/WB (MW_pipeline) Register
    input  logic [63:0] ALUResult_W,             // ALU result (used for arithmetic/logic operations)
    input  logic [63:0] ReadData_W,              // data read from memory (used for load operations)
    input  logic [63:0] PCPlus4_W,               // PC+4 value (used for JAL/JALR return address)
    
    // Control Input from MEM/WB (MW_pipeline) Register
    input  logic [1:0]  ResultSrc_W,             // result source selector:
                                                 // 2'b00 = ALU result (arithmetic/logic/branch)
                                                 // 2'b01 = memory read data (load operations)
                                                 // 2'b10 = PC+4 (JAL/JALR return address)
                                                 // 2'b11 = reserved/unused
    
    // Final Output (fed back to Decode Stage for register file write-back)
    output logic [63:0] Result_W                 // final 64-bit value to write to register file
);
    
    // ============================================================
    // WRITEBACK RESULT MULTIPLEXER
    // ============================================================
    // Selects which result (ALU/Memory/PC+4) gets written back to the register file
    // The selection is controlled by ResultSrc_W from the Memory/Writeback pipeline register
    
    assign Result_W = (ResultSrc_W == 2'b00) ? ALUResult_W :  // ALU result (default for most operations)
                      (ResultSrc_W == 2'b01) ? ReadData_W  :  // Memory read data (for load instructions)
                      (ResultSrc_W == 2'b10) ? PCPlus4_W   :  // PC+4 (for JAL/JALR to save return address)
                      64'b0;                                   // undefined (should not occur in normal operation)


endmodule