module control_unit (
    input  logic [6:0]  op,          // Full 7-bit opcode
    input  logic [2:0]  funct3,      
    input  logic        funct7_5,    
    input  logic        funct7_1,    
    output logic [1:0]  ResultSrc,
    output logic        MemWrite,
    output logic        ALUSrc,
    output logic [2:0]  ImmSrc,
    output logic        RegWrite,
    output logic [4:0]  ALUControl,  
    output logic        Branch,
    output logic        Jump,
    output logic        is_jalr      
);

    logic [1:0] ALUOp;

    // --- SECTION 1: MAIN DECODER ---
    always_comb begin
        // Defaults to avoid latches
        Branch    = 1'b0; 
        Jump      = 1'b0; 
        RegWrite  = 1'b0; 
        MemWrite  = 1'b0;
        ResultSrc = 2'b00; 
        ALUSrc    = 1'b0; 
        ImmSrc    = 3'b000; 
        ALUOp     = 2'b00;
        is_jalr   = 1'b0;

        case (op)
            7'b0000011: begin // Load (ld, lw...)
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1; 
                ResultSrc = 2'b01; 
                ImmSrc    = 3'b000; 
            end
            7'b0100011: begin // Store (sd, sw...)
                ImmSrc    = 3'b001; 
                ALUSrc    = 1'b1; 
                MemWrite  = 1'b1;
            end
            7'b0110011: begin // R-type 64-bit
                RegWrite  = 1'b1; 
                ALUOp     = 2'b10;
            end
            7'b0111011: begin // R-type 32-bit Word
                RegWrite  = 1'b1; 
                ALUOp     = 2'b11;
            end
            7'b0010011: begin // I-type ALU 64-bit
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1; 
                ALUOp     = 2'b10;
                ImmSrc    = 3'b000;
            end
            7'b0011011: begin // I-type ALU 32-bit Word
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1; 
                ALUOp     = 2'b11;
                ImmSrc    = 3'b000;
            end
            7'b0110111: begin // LUI
                RegWrite  = 1'b1; 
                ImmSrc    = 3'b011; 
                ResultSrc = 2'b11; 
                ALUSrc    = 1'b1;  
            end
            7'b0010111: begin // AUIPC
                RegWrite  = 1'b1;
                ImmSrc    = 3'b011; // U-type
                ResultSrc = 2'b00; // ALU Result
                ALUSrc    = 1'b1;  // PC + Imm
                ALUOp     = 2'b10; // Use ALU Decoder (it will default to ADD)
            end
            7'b1100011: begin // Branch
                ImmSrc    = 3'b010; 
                ALUOp     = 2'b01; 
                Branch    = 1'b1;
            end
            7'b1101111: begin // JAL
                RegWrite  = 1'b1; 
                ImmSrc    = 3'b100; // Corrected to 100 for J-type
                ResultSrc = 2'b10; // Select PC + 4
                Jump      = 1'b1;
            end
            7'b1100111: begin // JALR
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1;  
                ImmSrc    = 3'b000; // I-type
                ResultSrc = 2'b10; // Select PC + 4
                Jump      = 1'b1;
                is_jalr   = 1'b1;  
                ALUOp     = 2'b00; 
            end
            default: ; 
        endcase
    end

    // --- SECTION 2: ALU DECODER ---
    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 5'b00000; // Addition

            2'b01: begin // Branch Operations
                case (funct3)
                    3'b000, 3'b001: ALUControl = 5'b00001; // BEQ/BNE (SUB)
                    3'b100, 3'b101: ALUControl = 5'b01010; // BLT/BGE (SLT)
                    3'b110, 3'b111: ALUControl = 5'b01011; // BLTU/BGEU (SLTU)
                    default:        ALUControl = 5'b00001;
                endcase
            end

            2'b10: begin // Standard 64-bit
                case (funct3)
                    3'b000: begin 
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b00001; // SUB
                        else                              ALUControl = 5'b00000; // ADD
                    end
                    3'b001: ALUControl = 5'b00101; // SLL
                    3'b010: begin 
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b10000; // sh1add
                        else                              ALUControl = 5'b01010; // SLT
                    end
                    3'b011: ALUControl = 5'b01011; // SLTU
                    3'b100: begin 
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b10001; // sh2add
                        else                              ALUControl = 5'b00100; // XOR
                    end
                    3'b101: begin 
                        if (funct7_5) ALUControl = 5'b00111; // SRA
                        else          ALUControl = 5'b00110; // SRL
                    end
                    3'b110: begin 
                        if (op == 7'b0110011 && funct7_5) ALUControl = 5'b10010; // sh3add
                        else                              ALUControl = 5'b00011; // OR
                    end
                    3'b111: ALUControl = 5'b00010; // AND
                    default: ALUControl = 5'b00000;
                endcase
            end

            2'b11: begin // Word Operations
                case (funct3)
                    3'b000: begin 
                        if (funct7_5)      ALUControl = 5'b01001; // SUBW
                        else if (funct7_1) ALUControl = 5'b10011; // ADD.UW
                        else               ALUControl = 5'b01000; // ADDW
                    end
                    3'b001: ALUControl = 5'b01100; // SLLW
                    3'b010: ALUControl = (funct7_1) ? 5'b10100 : 5'b01000; // SH1ADD.UW
                    3'b100: ALUControl = (funct7_1) ? 5'b10101 : 5'b01000; // SH2ADD.UW
                    3'b101: begin 
                        if (funct7_5) ALUControl = 5'b01110; // SRAW
                        else          ALUControl = 5'b01101; // SRLW
                    end
                    3'b110: ALUControl = (funct7_1) ? 5'b10110 : 5'b01000; // SH3ADD.UW
                    default: ALUControl = 5'b01000;
                endcase
            end
            default: ALUControl = 5'b00000;
        endcase
    end
endmodule