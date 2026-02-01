module control_unit (
    input  logic [6:2]  op,          // Changed from [6:3] to [6:2]
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
    output logic        is_jalr      // New output for Execute stage
);

    logic [1:0] ALUOp;

    // --- SECTION 1: MAIN DECODER ---
    always_comb begin
        // Defaults
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
            5'b00000: begin // Load (ld, lw...)
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1; 
                ResultSrc = 2'b01; 
                ImmSrc    = 3'b000; 
            end
            5'b01000: begin // Store (sd, sw...)
                ImmSrc    = 3'b001; 
                ALUSrc    = 1'b1; 
                MemWrite  = 1'b1;
            end
            5'b01100: begin // R-type 64-bit
                RegWrite  = 1'b1; 
                ALUOp     = 2'b10;
            end
            5'b01110: begin // R-type 32-bit Word
                RegWrite  = 1'b1; 
                ALUOp     = 2'b11;
            end
            5'b00100: begin // I-type ALU 64-bit
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1; 
                ALUOp     = 2'b10;
                ImmSrc    = 3'b000;
            end
            5'b00110: begin // I-type ALU 32-bit Word
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1; 
                ALUOp     = 2'b11;
                ImmSrc    = 3'b000;
            end
            5'b01011: begin // LUI
                RegWrite  = 1'b1; 
                ImmSrc    = 3'b011; 
                ResultSrc = 2'b11; 
                ALUSrc    = 1'b1;  
            end
            5'b11000: begin // Branch
                ImmSrc    = 3'b010; 
                ALUOp     = 2'b01; 
                Branch    = 1'b1;
            end
            5'b11011: begin // JAL
                RegWrite  = 1'b1; 
                ImmSrc    = 3'b011; // J-type
                ResultSrc = 2'b10; // PC + 4
                Jump      = 1'b1;
            end
            5'b11001: begin // JALR
                RegWrite  = 1'b1; 
                ALUSrc    = 1'b1;  // Use ImmExt for offset
                ImmSrc    = 3'b000; // I-type
                ResultSrc = 2'b10; // PC + 4
                Jump      = 1'b1;
                is_jalr   = 1'b1;  // Signal to Execute stage
                ALUOp     = 2'b00; // ALU performs ADD (rs1 + imm)
            end
            default: ; 
        endcase
    end
    // --- SECTION 2: ALU DECODER ---
    
    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 5'b00000; // Addition (Loads/Stores)

            2'b01: begin // --- Branch Operations ---
                case (funct3)
                    3'b000, 3'b001: ALUControl = 5'b00001; // BEQ/BNE (SUB)
                    3'b100, 3'b101: ALUControl = 5'b01010; // BLT/BGE (SLT)
                    3'b110, 3'b111: ALUControl = 5'b01011; // BLTU/BGEU (SLTU)
                    default:        ALUControl = 5'b00001;
                endcase
            end

            2'b10: begin // --- Standard 64-bit & Zba Operations ---
                case (funct3)
                    3'b000: begin // ADD / SUB / ADDI
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b00001; // SUB
                        else                           ALUControl = 5'b00000; // ADD / ADDI
                    end
                    3'b001: ALUControl = 5'b00101; // SLL / SLLI
                    3'b010: begin // SLT / SLTI or sh1add
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b10000; // sh1add
                        else                           ALUControl = 5'b01010; // SLT / SLTI
                    end
                    3'b011: ALUControl = 5'b01011; // SLTU / SLTIU
                    3'b100: begin // XOR / XORI or sh2add
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b10001; // sh2add
                        else                           ALUControl = 5'b00100; // XOR / XORI
                    end
                    3'b101: begin // SRL / SRA
                        if (funct7_5)                  ALUControl = 5'b00111; // SRA
                        else                           ALUControl = 5'b00110; // SRL
                    end
                    3'b110: begin // OR / ORI or sh3add
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b10010; // sh3add
                        else                           ALUControl = 5'b00011; // OR / ORI
                    end
                    3'b111: ALUControl = 5'b00010; // AND / ANDI
                    default: ALUControl = 5'b00000;
                endcase
            end

            2'b11: begin // --- Word (32-bit) & Zba.uw Operations ---
                case (funct3)
                    3'b000: begin // ADDW / SUBW / ADDIW / add.uw
                        if (op == 4'b0111 && funct7_5)      ALUControl = 5'b01001; // SUBW
                        else if (op == 4'b0111 && funct7_1) ALUControl = 5'b10011; // add.uw
                        else                                ALUControl = 5'b01000; // ADDW / ADDIW
                    end
                    3'b001: ALUControl = 5'b01100; // SLLW / SLLIW
                    3'b010: ALUControl = 5'b10100; // sh1add.uw
                    3'b100: ALUControl = 5'b10101; // sh2add.uw
                    3'b101: begin // SRLW / SRAW
                        if (funct7_5)  ALUControl = 5'b01110; // SRAW
                        else           ALUControl = 5'b01101; // SRLW
                    end
                    3'b110: ALUControl = 5'b10110; // sh3add.uw
                    default: ALUControl = 5'b01000;
                endcase
            end
            default: ALUControl = 5'b00000;
        endcase
    end
endmodule