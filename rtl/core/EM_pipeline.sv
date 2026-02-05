// File: rtl/core/EM_pipeline.sv
// Brief: Execute->Memory pipeline register. Passes ALU results,
// write data and control signals to Memory stage.
module EM_pipeline (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset
    input  logic        clr,                     // clear/flush signal
    
    // Data Signals from Execute (E) stage
    input  logic [63:0] ALUResult_E,             // ALU result (used as memory address for load/store)
    input  logic [63:0] WriteData_E,             // data to be written to memory (store operand)
    input  logic [4:0]  Rd_E,                   // destination register index from Execute
    input  logic [63:0] PCPlus4_E,              // PC+4 from Execute (for JAL/JALR return address)
    
    // Control Signals from Execute (E) stage
    input  logic        RegWrite_E,             // register file write enable flag
    input  logic [1:0]  ResultSrc_E,           // writeback source selector (ALU/Mem/PC+4)
    input  logic        MemWrite_E,            // memory write enable flag
    
    // Data Signals to Memory (M) stage
    output logic [63:0] ALUResult_M,            // latched ALU result (address for memory operations)
    output logic [63:0] WriteData_M,            // latched data for memory write (store data)
    output logic [4:0]  Rd_M,                  // latched destination register index
    output logic [63:0] PCPlus4_M,             // latched PC+4 for writeback
    
    // Control Signals to Memory (M) stage
    output logic        RegWrite_M,             // latched register write enable
    output logic [1:0]  ResultSrc_M,           // latched result source selector
    output logic        MemWrite_M              // latched memory write enable
);

    // Pipeline register: latches Execute results and control signals for Memory stage
    // When rst or clr is asserted, all outputs clear to NOP values
    always_ff @(posedge clk or posedge rst or posedge clr) begin
        if (rst || clr) begin
            // Clear phase: zero all latched outputs to produce NOP in Memory stage
            ALUResult_M <= 64'b0;       // result -> 0
            WriteData_M <= 64'b0;       // store data -> 0
            Rd_M        <= 5'b0;        // destination register -> 0 (writes to x0, disabled)
            PCPlus4_M   <= 64'b0;       // PC+4 -> 0
            RegWrite_M  <= 1'b0;        // disable register write
            ResultSrc_M <= 2'b0;        // select ALU result (inconsequential with RegWrite=0)
            MemWrite_M  <= 1'b0;        // disable memory write
        end else begin
            // Normal phase: latch all Execute stage outputs on rising clock edge
            ALUResult_M <= ALUResult_E; // latch ALU result (memory address or value)
            WriteData_M <= WriteData_E; // latch store data for memory write
            Rd_M        <= Rd_E;        // latch destination register index
            PCPlus4_M   <= PCPlus4_E;   // latch PC+4 (used for JAL/JALR return address)
            RegWrite_M  <= RegWrite_E;  // latch register write enable flag
            ResultSrc_M <= ResultSrc_E; // latch writeback source selector
            MemWrite_M  <= MemWrite_E;  // latch memory write enable flag
        end
    end

endmodule