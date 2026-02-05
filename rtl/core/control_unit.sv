// File: rtl/core/control_unit.sv
// Brief: Main control unit for the pipeline. Decodes opcode and funct fields
// to produce control signals for ALU, register file, memory and branching.
// Inputs: `op`, `funct3`, `funct7_5`, `funct7_1`. Outputs: control bus signals.

module control_unit (
    input  logic [6:0]  op,         // opcode field (Instr[6:0])
    input  logic [2:0]  funct3,     // funct3 field (Instr[14:12])
    input  logic        funct7_5,   // bit[30] of funct7 (used to distinguish SUB/SRA/etc.)
    input  logic        funct7_1,   // bit[25] of funct7 or other extension bit

    output logic [1:0]  ResultSrc,  // 00=ALU, 01=Mem, 10=PC+4, 11=LUI/IMM
    output logic        MemWrite,   // memory write enable
    output logic        ALUSrc,     // 0=reg, 1=imm (ALU second operand)
    output logic [2:0]  ImmSrc,     // immediate format selector (I/S/B/U/J)
    output logic        RegWrite,   // register file write enable
    output logic [4:0]  ALUControl, // micro ALU operation encoding
    output logic        Branch,     // branch instruction indicator
    output logic        Jump,       // jump instruction indicator (JAL/JALR)
    output logic        is_jalr     // specifically JALR (affects target computation)
);

    // ALUOp: high-level ALU class used by ALU decoder stage
    // 00 -> default ADD, 01 -> branch compare, 10 -> R/I 64-bit, 11 -> Word ops/.UW
    logic [1:0] ALUOp;

    // -----------------------
    // SECTION 1: MAIN DECODER
    // Sets control signals common to instruction opcode classes
    // -----------------------
    always_comb begin
        // Default (safe) values
        Branch    = 1'b0;
        Jump      = 1'b0;
        RegWrite  = 1'b0;
        MemWrite  = 1'b0;
        ResultSrc = 2'b00;
        ALUSrc    = 1'b0;
        ImmSrc    = 3'b000;
        ALUOp     = 2'b00;
        is_jalr   = 1'b0;

        // Decode by opcode
        case (op)
            7'b0000011: begin // LOAD (I-type loads)
                RegWrite  = 1'b1;     // write loaded value to rd
                ALUSrc    = 1'b1;     // use immediate for address calc
                ResultSrc = 2'b01;    // select memory read for writeback
                ImmSrc    = 3'b000;   // I-type immediate
            end

            7'b0100011: begin // STORE (S-type)
                ImmSrc = 3'b001;     // S-type immediate
                ALUSrc = 1'b1;       // ALU uses imm for address
                MemWrite = 1'b1;     // enable memory write
            end

            7'b0110011: begin // R-type 64-bit (register-register)
                RegWrite = 1'b1;
                ALUOp = 2'b10;       // go to ALU decoder for R-type
            end

            7'b0111011: begin // R-type 32-bit (word) R-type
                RegWrite = 1'b1;
                ALUOp = 2'b11;       // word/.UW ALU decoding
            end

            7'b0010011: begin // I-type 64-bit (immediate ALU ops)
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                ALUOp = 2'b10;       // reuse 64-bit ALU decoder
                ImmSrc = 3'b000;     // I-type immediate
            end

            7'b0011011: begin // I-type 32-bit word immediate (ADDIW, etc.)
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                ALUOp = 2'b11;       // word/.UW decoding
                ImmSrc = 3'b000;
            end

            7'b0110111: begin // LUI
                RegWrite = 1'b1;
                ImmSrc = 3'b011;     // U-type immediate
                ResultSrc = 2'b11;   // select immediate/upper for writeback
                ALUSrc = 1'b1;
            end

            7'b0010111: begin // AUIPC
                RegWrite = 1'b1;
                ImmSrc = 3'b011;     // U-type immediate
                ResultSrc = 2'b00;   // ALU (PC + imm) -> writeback
                ALUSrc = 1'b1;
                ALUOp = 2'b10;
            end

            7'b1100011: begin // Branches (B-type)
                ImmSrc = 3'b010;     // B-type immediate
                ALUOp = 2'b01;       // ALUOp for branch comparison
                Branch = 1'b1;
            end

            7'b1101111: begin // JAL (J-type)
                RegWrite = 1'b1;
                ImmSrc = 3'b100;     // J-type immediate
                ResultSrc = 2'b10;   // write PC+4
                Jump = 1'b1;
            end

            7'b1100111: begin // JALR (I-type, indirect jump)
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                ImmSrc = 3'b000;     // I-type immediate
                ResultSrc = 2'b10;   // write PC+4
                Jump = 1'b1;
                is_jalr = 1'b1;      // mark as JALR for target calc
                ALUOp = 2'b00;       // ALU performs ADD for target
            end

            default: ; // leave defaults
        endcase
    end


    // -----------------------
    // SECTION 2: ALU DECODER
    // Translate `ALUOp` + funct fields into concrete ALUControl codes
    // -----------------------
    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 5'b00000; // default ADD (used by loads/stores/JALR)

            2'b01: begin // Branch comparisons -> map to SUB/SLT/SLTU
                case (funct3)
                    3'b000, 3'b001: ALUControl = 5'b00001; // BEQ/BNE -> SUB
                    3'b100, 3'b101: ALUControl = 5'b01010; // BLT/BGE -> SLT
                    3'b110, 3'b111: ALUControl = 5'b01011; // BLTU/BGEU -> SLTU
                    default:        ALUControl = 5'b00001;
                endcase
            end

            2'b10: begin // 64-bit R-type / I-type arithmetic & shifts
                case (funct3)
                    3'b000: begin
                        // funct7[5] distinguishes ADD vs SUB for R-type
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b00001; // SUB
                        else                              ALUControl = 5'b00000; // ADD
                    end
                    3'b001: ALUControl = 5'b00101; // SLL
                    3'b010: begin
                        // Some encodings use funct7[5] for SH1ADD Zba; otherwise SLT
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b10000; // SH1ADD
                        else                              ALUControl = 5'b01010; // SLT
                    end
                    3'b011: ALUControl = 5'b01011; // SLTU
                    3'b100: begin
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b10001; // SH2ADD
                        else                              ALUControl = 5'b00100; // XOR
                    end
                    3'b101: ALUControl = (funct7_5) ? 5'b00111 : 5'b00110; // SRA : SRL
                    3'b110: begin
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b10010; // SH3ADD
                        else                              ALUControl = 5'b00011; // OR
                    end
                    3'b111: ALUControl = 5'b00010; // AND
                    default: ALUControl = 5'b00000;
                endcase
            end

            2'b11: begin // 32-bit word ops and .UW encodings
                case (funct3)
                    3'b000: begin
                        if (funct7_5)      ALUControl = 5'b01001; // SUBW
                        else if (funct7_1) ALUControl = 5'b10011; // ADD.UW
                        else               ALUControl = 5'b01000; // ADDW
                    end
                    3'b001: ALUControl = 5'b01100; // SLLW
                    3'b010: ALUControl = (funct7_1) ? 5'b10100 : 5'b01000; // SH1ADD.UW or ADDW
                    3'b100: ALUControl = (funct7_1) ? 5'b10101 : 5'b01000; // SH2ADD.UW or ADDW
                    3'b101: ALUControl = (funct7_5) ? 5'b01110 : 5'b01101; // SRAW : SRLW
                    3'b110: ALUControl = (funct7_1) ? 5'b10110 : 5'b01000; // SH3ADD.UW or ADDW
                    default: ALUControl = 5'b01000;
                endcase
            end

            default: ALUControl = 5'b00000; // fallback to ADD
        endcase
    end
endmodule