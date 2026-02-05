// File: rtl/core/immediate.sv
// Brief: Immediate value generator. Extracts and sign-extends or zero-extends
// immediate values from 32-bit instruction based on instruction format.
// Supports I-type, S-type, B-type, U-type, and J-type immediates.
module immediate (
    input  logic [31:0] Instr,                  // 32-bit instruction input
    input  logic [2:0]  ImmSrc,                 // immediate source selector:
                                                // 000 = I-type, 001 = S-type, 010 = B-type
                                                // 011 = U-type, 100 = J-type, others = reserved
    output logic [63:0] ImmExt                  // 64-bit sign-extended immediate output
);

    // ============================================================
    // IMMEDIATE EXTRACTION FOR EACH INSTRUCTION FORMAT
    // ============================================================
    
    // I-TYPE IMMEDIATE (used by ADDI, LW, JALR, etc.)
    // 12-bit signed immediate from bits [31:20]
    // Sign-extended to 64 bits using bit [31] as sign bit
    wire [63:0] i_imm = { {52{Instr[31]}}, Instr[31:20] };

    // S-TYPE IMMEDIATE (used by SW, SD stores)
    // 12-bit signed immediate split: bits [31:25] | bits [11:7]
    // Sign-extended to 64 bits
    wire [63:0] s_imm = { {52{Instr[31]}}, Instr[31:25], Instr[11:7] };

    // B-TYPE IMMEDIATE (used by BEQ, BNE, BLT, etc. branch instructions)
    // 13-bit signed immediate with bit 0 always 0 (word-aligned offsets)
    // Format: Instr[31] | Instr[7] | Instr[30:25] | Instr[11:8] | 0
    // Sign-extended to 64 bits
    wire [63:0] b_imm = { {51{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0 };

    // U-TYPE IMMEDIATE (used by LUI, AUIPC upper address instructions)
    // 32-bit value placed in upper 32 bits of result (bits [31:12] of instr)
    // Lower 12 bits are zeroed; sign-extended from bit [31]
    wire [63:0] u_imm = { {32{Instr[31]}}, Instr[31:12], 12'b0 };

    // J-TYPE IMMEDIATE (used by JAL jump instruction)
    // 21-bit signed immediate with bit 0 always 0 (word-aligned targets)
    // Bits are scrambled in instruction: [31] | [19:12] | [20] | [30:21] | 0
    // Sign-extended to 64 bits
    wire [63:0] j_imm = { {43{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0 };

    // ============================================================
    // IMMEDIATE MULTIPLEXER
    // ============================================================
    // Selects which immediate format to use based on ImmSrc control signal
    // from the control unit (based on instruction opcode and funct fields)
    
    always_comb begin
        case (ImmSrc)
            3'b000:  ImmExt = i_imm;            // I-type: ADDI, LW, JALR, etc.
            3'b001:  ImmExt = s_imm;            // S-type: SW, SD
            3'b010:  ImmExt = b_imm;            // B-type: BEQ, BNE, BLT, etc.
            3'b011:  ImmExt = u_imm;            // U-type: LUI, AUIPC
            3'b100:  ImmExt = j_imm;            // J-type: JAL
            default: ImmExt = 64'b0;            // undefined immediate (should not occur)
        endcase
    end
endmodule