module control_unit (
    input  logic [6:3]  op,          // Instr[6:3]
    input  logic [2:0]  funct3,      // Instr[14:12]
    input  logic        funct7_5,    // Instr[30]
    input  logic        funct7_1,    // Instr[25]
    output logic [1:0]  ResultSrc,
    output logic        MemWrite,
    output logic        ALUSrc,
    output logic [2:0]  ImmSrc,
    output logic        RegWrite,
    output logic [4:0]  ALUControl,  // Kept at 5-bit for expansion
    output logic        Branch,
    output logic        Jump
);

    logic [1:0] ALUOp;

    always_comb begin
        // --- Default Assignments ---
        Branch    = 1'b0; Jump = 1'b0; RegWrite = 1'b0; MemWrite = 1'b0;
        ResultSrc = 2'b00; ALUSrc = 1'b0; ImmSrc = 3'b000; ALUOp = 2'b00;

        case (op)
            4'b0000: begin // Load (ld, lw)
                RegWrite = 1'b1; ALUSrc = 1'b1; ResultSrc = 2'b01;
            end
            4'b0100: begin // Store (sd, sw)
                ImmSrc = 3'b001; ALUSrc = 1'b1; MemWrite = 1'b1;
            end
            4'b0110: begin // R-type (64-bit)
                RegWrite = 1'b1; ALUOp = 2'b10;
            end
            4'b0111: begin // R-type Word (ADDW, SUBW, shNadd.uw)
                RegWrite = 1'b1; ALUOp = 2'b11;
            end
            4'b0010: begin // I-type ALU (64-bit)
                RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = 2'b10;
            end
            4'b0011: begin // I-type Word (ADDIW)
                RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = 2'b11;
            end
            4'b0101: begin // U-type (LUI)
                RegWrite = 1'b1; ImmSrc = 3'b011; ResultSrc = 2'b11; ALUSrc = 1'b1;  
            end
            default: ; 
        endcase
    end

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 5'b00000; // Addition
            
            // --- Standard 64-bit & Zba Operations ---
            2'b10: begin
                case (funct3)
                    3'b000: begin // ADD / SUB
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b00001; // SUB
                        else                           ALUControl = 5'b00000; // ADD / ADDI
                    end
                    3'b111: ALUControl = 5'b00010; // AND / ANDI
                    3'b110: begin // sh3add (Zba) OR OR
                         if (op == 4'b0110 && funct7_5) ALUControl = 5'b10010; // sh3add
                         else                           ALUControl = 5'b00011; // OR / ORI
                    end
                    3'b100: begin // sh2add (Zba) OR XOR
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b10001; // sh2add
                        else                           ALUControl = 5'b00100; // XOR / XORI
                    end
                    3'b010: begin // sh1add (Zba) 
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b10000; // sh1add
                        else                           ALUControl = 5'b00000; // Default ADD
                    end
                    default: ALUControl = 5'b00000;
                endcase
            end

            // --- Word (32-bit) & Zba.uw Operations ---
            2'b11: begin
                case (funct3)
                    3'b000: begin
                        if (op == 4'b0111 && funct7_5)      ALUControl = 5'b01001; // SUBW
                        else if (op == 4'b0111 && funct7_1) ALUControl = 5'b10011; // add.uw
                        else                                ALUControl = 5'b01000; // ADDW / ADDIW
                    end
                    3'b010: ALUControl = 5'b10100; // sh1add.uw
                    3'b100: ALUControl = 5'b10101; // sh2add.uw
                    3'b110: ALUControl = 5'b10110; // sh3add.uw
                    default: ALUControl = 5'b01000;
                endcase
            end
            default: ALUControl = 5'b00000;
        endcase
    end
endmodule