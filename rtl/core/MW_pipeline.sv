// File: rtl/core/MW_pipeline.sv
// Brief: Memory->Writeback pipeline register. Latches memory read data,
// ALU results and control signals for the final writeback stage.
module MW_pipeline (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset
    
    // Data Signals from Memory (M) stage
    input  logic [63:0] ALUResult_M,             // ALU result computed in Execute (passed through Memory)
    input  logic [63:0] ReadData_M,             // data read from memory in load operations
    input  logic [4:0]  Rd_M,                   // destination register index from Memory stage
    input  logic [63:0] PCPlus4_M,              // PC+4 value from Memory stage (for JAL/JALR)
    
    // Control Signals from Memory (M) stage
    input  logic        RegWrite_M,             // register file write enable from Memory
    input  logic [1:0]  ResultSrc_M,           // writeback source selector from Memory
    
    // Data Signals to Writeback (W) stage
    output logic [63:0] ALUResult_W,            // latched ALU result for writeback
    output logic [63:0] ReadData_W,             // latched memory read data (load result)
    output logic [4:0]  Rd_W,                  // latched destination register index
    output logic [63:0] PCPlus4_W,             // latched PC+4 (for JAL/JALR return address write)
    
    // Control Signals to Writeback (W) stage
    output logic        RegWrite_W,             // latched register write enable
    output logic [1:0]  ResultSrc_W             // latched writeback source selector
);

    // Pipeline register: latches Memory results and control signals for final Writeback stage
    // On reset, all outputs clear to NOP values
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset phase: zero all latched outputs
            ALUResult_W <= 64'b0;       // ALU result -> 0
            ReadData_W  <= 64'b0;       // memory read data -> 0
            Rd_W        <= 5'b0;        // destination register -> 0 (writes to x0, disabled)
            PCPlus4_W   <= 64'b0;       // PC+4 -> 0
            RegWrite_W  <= 1'b0;        // disable register write
            ResultSrc_W <= 2'b0;        // select ALU result (inconsequential with RegWrite=0)
        end else begin
            // Normal phase: latch all Memory stage outputs on rising clock edge
            ALUResult_W <= ALUResult_M; // latch ALU result (used for most operations)
            ReadData_W  <= ReadData_M;  // latch memory read data (from load operations)
            Rd_W        <= Rd_M;        // latch destination register index for writeback
            PCPlus4_W   <= PCPlus4_M;   // latch PC+4 (used for JAL/JALR return address)
            RegWrite_W  <= RegWrite_M;  // latch register write enable flag
            ResultSrc_W <= ResultSrc_M; // latch writeback source selector (chooses ALU/Mem/PC+4)
        end
    end

endmodule