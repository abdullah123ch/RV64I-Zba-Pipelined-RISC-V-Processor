// File: rtl/core/alu.sv
// Brief: Arithmetic Logic Unit for RV64I with Zba (.UW) support.
// Inputs: SrcA, SrcB (64-bit), ALUControl selects operation.
// Outputs: ALUResult (64-bit), Zero flag when result == 0.
// Notes: Control encodings are defined/selected by control_unit.sv.

module alu (
    input  logic [63:0] SrcA, SrcB,       // operands A and B (64-bit)
    input  logic [4:0]  ALUControl,      // operation selector
    output logic [63:0] ALUResult,       // computed result (64-bit)
    output logic        Zero             // high when ALUResult == 0
);

    // 1. Prepare Word (32-bit) views of inputs for word operations
    wire [31:0] a32 = SrcA[31:0];        // low 32 bits of SrcA
    wire [31:0] b32 = SrcB[31:0];        // low 32 bits of SrcB
    wire [63:0] a_uw = {32'b0, a32};     // zero-extend 32-bit A for .uw ops

    // 2. Pre-calculate 32-bit results used by ADDW/SUBW/shift-word ops
    wire [31:0] sum32 = a32 + b32;                      // 32-bit add
    wire [31:0] sub32 = a32 - b32;                      // 32-bit sub
    wire [31:0] sll32 = a32 << SrcB[4:0];               // logical left (word)
    wire [31:0] srl32 = a32 >> SrcB[4:0];               // logical right (word)
    wire [31:0] sra32 = $signed(a32) >>> SrcB[4:0];     // arithmetic right (word)

    // 3. Zba extension helpers (64-bit shifts of A and A zero-extended)
    wire [63:0] sh1_a   = SrcA << 1;   // A << 1 (64-bit)
    wire [63:0] sh2_a   = SrcA << 2;   // A << 2 (64-bit)
    wire [63:0] sh3_a   = SrcA << 3;   // A << 3 (64-bit)

    wire [63:0] sh1_auw = a_uw << 1;   // (A.UW) << 1
    wire [63:0] sh2_auw = a_uw << 2;   // (A.UW) << 2
    wire [63:0] sh3_auw = a_uw << 3;   // (A.UW) << 3

    // 4. Final Result Selection: choose operation based on ALUControl
    always_comb begin
        case (ALUControl)
            // 64-bit arithmetic / logical
            5'b00000: ALUResult = SrcA + SrcB;                        // ADD
            5'b00001: ALUResult = SrcA - SrcB;                        // SUB
            5'b00010: ALUResult = SrcA & SrcB;                        // AND
            5'b00011: ALUResult = SrcA | SrcB;                        // OR
            5'b00100: ALUResult = SrcA ^ SrcB;                        // XOR
            5'b00101: ALUResult = SrcA << SrcB[5:0];                  // SLL (64-bit)
            5'b00110: ALUResult = SrcA >> SrcB[5:0];                  // SRL (logical)
            5'b00111: ALUResult = $signed(SrcA) >>> SrcB[5:0];        // SRA (arithmetic)

            // 32-bit (word) operations then sign-extend to 64-bit
            5'b01000: ALUResult = {{32{sum32[31]}}, sum32};          // ADDW (sign-extend)
            5'b01001: ALUResult = {{32{sub32[31]}}, sub32};          // SUBW (sign-extend)
            5'b01100: ALUResult = {{32{sll32[31]}}, sll32};          // SLLW -> sign-extend
            5'b01101: ALUResult = {{32{srl32[31]}}, srl32};          // SRLW -> sign-extend
            5'b01110: ALUResult = {{32{sra32[31]}}, sra32};          // SRAW -> sign-extend

            // Zba bit-manipulation patterns (shXadd variants)
            5'b10000: ALUResult = SrcB + sh1_a;                      // SH1ADD: (A<<1) + B
            5'b10001: ALUResult = SrcB + sh2_a;                      // SH2ADD: (A<<2) + B
            5'b10010: ALUResult = SrcB + sh3_a;                      // SH3ADD: (A<<3) + B

            // Zba .UW variants: zero-extend A before shifting and adding
            5'b10011: ALUResult = SrcB + a_uw;                       // ADD.UW: zero-extend A + B
            5'b10100: ALUResult = SrcB + sh1_auw;                    // SH1ADD.UW
            5'b10101: ALUResult = SrcB + sh2_auw;                    // SH2ADD.UW
            5'b10110: ALUResult = SrcB + sh3_auw;                    // SH3ADD.UW

            // Comparisons (produce 1 or 0)
            5'b01010: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 64'd1 : 64'd0; // SLT
            5'b01011: ALUResult = (SrcA < SrcB) ? 64'd1 : 64'd0;                   // SLTU

            default:  ALUResult = 64'b0;                                    // default -> zero
        endcase
    end

    // Zero flag asserted when ALUResult equals zero
    assign Zero = (ALUResult == 64'b0);
endmodule