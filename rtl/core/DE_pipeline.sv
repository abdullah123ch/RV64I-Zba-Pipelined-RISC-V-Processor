// File: rtl/core/DE_pipeline.sv
// Brief: Decode->Execute pipeline register. Transfers decoded operands,
// immediates and control signals to Execute stage; supports enable/clear.
module DE_pipeline (
    input  logic        clk,                     // system clock
    input  logic        rst,                     // synchronous reset
    input  logic        clr,                     // clear/flush (on branch/mispredict)

    // Data Signals from Decode (D) stage
    input  logic [63:0] RD1_D, RD2_D,           // register operands from regfile
    input  logic [63:0] PC_D,                   // program counter from IF/ID
    input  logic [63:0] ImmExt_D,               // sign/zero-extended immediate
    input  logic [4:0]  Rd_D, Rs1_D, Rs2_D,    // register indices (destination/sources)
    input  logic [6:0]  op_D,                   // opcode for AUIPC/branch detection

    // Control Signals from Decode (D) stage
    input  logic        RegWrite_D,             // register file write enable
    input  logic        MemWrite_D,             // memory write enable
    input  logic        ALUSrc_D,               // ALU operand B source (reg vs imm)
    input  logic        Branch_D,               // branch instruction flag
    input  logic        Jump_D,                 // jump (JAL/JALR) instruction flag
    input  logic [1:0]  ResultSrc_D,           // writeback source selector
    input  logic [4:0]  ALUControl_D,          // ALU operation code
    input  logic [2:0]  funct3_D,              // funct3 field for branch conditions
    input  logic        is_jalr_D,             // indicates JALR (indirect jump)

    // Data Signals to Execute (E) stage
    output logic [63:0] RD1_E, RD2_E,           // latched register operands
    output logic [63:0] PC_E,                   // latched PC (used by AUIPC/JAL)
    output logic [63:0] ImmExt_E,               // latched immediate
    output logic [4:0]  Rd_E, Rs1_E, Rs2_E,    // latched register indices
    output logic [6:0]  op_E,                   // latched opcode to Execute stage

    // Control Signals to Execute (E) stage
    output logic        RegWrite_E,             // latched register write enable
    output logic        MemWrite_E,             // latched memory write enable
    output logic        ALUSrc_E,               // latched ALU source select
    output logic        Branch_E,               // latched branch flag
    output logic        Jump_E,                 // latched jump flag
    output logic [1:0]  ResultSrc_E,           // latched writeback source
    output logic [4:0]  ALUControl_E,          // latched ALU control code
    output logic [2:0]  funct3_E,              // latched funct3 for branch logic
    output logic        is_jalr_E               // latched JALR indicator
);

    // Pipeline register: latches all data and control signals on clock edge
    // When rst or clr is asserted, all outputs clear to default (NOP) values
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clr) begin
            // Clear phase: zero all outputs to produce NOP in Execute stage
            RD1_E        <= 64'b0;        // operand A -> 0
            RD2_E        <= 64'b0;        // operand B -> 0
            PC_E         <= 64'b0;        // PC -> 0
            ImmExt_E     <= 64'b0;        // immediate -> 0
            Rd_E         <= 5'b0;         // destination register -> 0 (writes to x0)
            Rs1_E        <= 5'b0;         // source 1 index -> 0
            Rs2_E        <= 5'b0;         // source 2 index -> 0
            op_E         <= 7'b0;         // opcode -> 0
            RegWrite_E   <= 1'b0;         // disable register write
            ResultSrc_E  <= 2'b00;        // select ALU result (inconsequential with RegWrite=0)
            MemWrite_E   <= 1'b0;         // disable memory write
            ALUControl_E <= 5'b0;         // ALU operation -> ADD (inconsequential)
            ALUSrc_E     <= 1'b0;         // ALU source -> register (inconsequential)
            Branch_E     <= 1'b0;         // not a branch
            Jump_E       <= 1'b0;         // not a jump
            funct3_E     <= 3'b0;         // funct3 -> 0
            is_jalr_E    <= 1'b0;         // not JALR

        end else begin
            // Normal phase: latch all inputs to outputs on rising clock edge
            RD1_E        <= RD1_D;        // latch register operand A
            RD2_E        <= RD2_D;        // latch register operand B
            PC_E         <= PC_D;         // latch program counter
            ImmExt_E     <= ImmExt_D;     // latch extended immediate
            Rd_E         <= Rd_D;         // latch destination register index
            Rs1_E        <= Rs1_D;        // latch source 1 register index
            Rs2_E        <= Rs2_D;        // latch source 2 register index
            op_E         <= op_D;         // latch opcode for Execute stage
            RegWrite_E   <= RegWrite_D;   // latch register write enable
            ResultSrc_E  <= ResultSrc_D;  // latch writeback source selector
            MemWrite_E   <= MemWrite_D;   // latch memory write enable
            ALUControl_E <= ALUControl_D; // latch ALU control code
            ALUSrc_E     <= ALUSrc_D;     // latch ALU operand B source
            Branch_E     <= Branch_D;     // latch branch flag
            Jump_E       <= Jump_D;       // latch jump flag
            funct3_E     <= funct3_D;     // latch funct3 for branch conditions
            is_jalr_E    <= is_jalr_D;    // latch JALR indicator
        end
    end

endmodule