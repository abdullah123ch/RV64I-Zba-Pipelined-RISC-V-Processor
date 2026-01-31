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
    output logic [4:0]  ALUControl,  
    output logic        Branch,
    output logic        Jump
);

    logic [1:0] ALUOp;

    always_comb begin
        // --- Default Assignments ---
        Branch    = 1'b0;
        Jump      = 1'b0;
        RegWrite  = 1'b0;
        MemWrite  = 1'b0;
        ResultSrc = 2'b00;
        ALUSrc    = 1'b0;
        ImmSrc    = 3'b000;
        ALUOp     = 2'b00;

        case (op)
            4'b0000: begin // Load (ld, lw)
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ResultSrc = 2'b01;
            end
            4'b0100: begin // Store (sd, sw)
                ImmSrc    = 3'b001;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b1;
            end
            4'b0110: begin // R-type (64-bit)
                RegWrite  = 1'b1;
                ALUOp     = 2'b10;
            end
            4'b0111: begin // R-type Word (ADDW, SUBW)
                RegWrite  = 1'b1;
                ALUOp     = 2'b11;
            end
            4'b0010: begin // I-type ALU (64-bit)
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ALUOp     = 2'b10;
            end
            4'b0011: begin // I-type Word (ADDIW)
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ALUOp     = 2'b11;
            end
            4'b1100: begin // B-type (branch)
                ImmSrc    = 3'b010; 
                ALUOp     = 2'b01;  
                Branch    = 1'b1;   
            end
            4'b0101: begin // U-type
                RegWrite  = 1'b1;
                ImmSrc    = 3'b011; 
                ResultSrc = 2'b11; 
                ALUSrc    = 1'b1;  
            end
            4'b1101: begin // J-type
                RegWrite  = 1'b1;
                ImmSrc    = 3'b100; 
                ResultSrc = 2'b10;  
                Jump      = 1'b1;   
            end
            default: ; 
        endcase
    end

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 5'b00000; // Addition
            2'b01: ALUControl = 5'b00001; // Subtraction
            
            // --- Standard 64-bit Operations ---
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (op == 4'b0110 && funct7_5) ALUControl = 5'b00001; // SUB
                        else                           ALUControl = 5'b00000; // ADD/ADDI
                    end
                    3'b111: ALUControl = 5'b00010; // AND
                    3'b110: begin 
                         if (funct7_5)                 ALUControl = 5'b10010; // sh3add (Zba)
                         else                          ALUControl = 5'b00011; // OR
                    end
                    3'b100: ALUControl = 5'b00100; // XOR
                    3'b001: ALUControl = 5'b00101; // SLL
                    3'b101: ALUControl = (funct7_5) ? 5'b00111 : 5'b00110; // SRA : SRL
                    default: ALUControl = 5'b00000;
                endcase
            end

            // --- Word (32-bit) Operations ---
            2'b11: begin
                case (funct3)
                    3'b000: begin
                        if (op == 4'b0111 && funct7_5) ALUControl = 5'b01001; // SUBW
                        else                           ALUControl = 5'b01000; // ADDW/ADDIW
                    end
                    3'b001: ALUControl = 5'b01010; // SLLW/SLLIW
                    3'b101: ALUControl = (funct7_5) ? 5'b01100 : 5'b01011; // SRAW/SRAIW : SRLW/SRLIW
                    default: ALUControl = 5'b01000;
                endcase
            end
            
            default: ALUControl = 5'b00000;
        endcase
    end
    
endmodule