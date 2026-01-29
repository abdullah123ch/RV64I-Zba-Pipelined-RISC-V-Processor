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
    output logic [3:0]  ALUControl,  
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
            4'b0000: begin // lw / ld (Load)
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ResultSrc = 2'b01;
            end
            4'b0100: begin // sw / sd (Store)
                ImmSrc    = 3'b001;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b1;
            end
            4'b0110: begin // R-type
                RegWrite  = 1'b1;
                ALUOp     = 2'b10;
            end
            4'b0010: begin // I-type ALU
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                ALUOp     = 2'b10;
            end
            4'b1100: begin // B-type (beq)
                ImmSrc    = 3'b010; 
                ALUOp     = 2'b01;  
                Branch    = 1'b1;   
            end
            4'b1101: begin // J-type (jal)
                RegWrite  = 1'b1;
                ImmSrc    = 3'b011; 
                ResultSrc = 2'b10;  
                Jump      = 1'b1;   
            end
            default: ; 
        endcase
    end

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0000; // Addition
            2'b01: ALUControl = 4'b0001; // Subtraction
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (op == 4'b0110 && funct7_5) ALUControl = 4'b0001; // SUB
                        else                           ALUControl = 4'b0000; // ADD/ADDI
                    end
                    // --- Logical ---
                    3'b111: ALUControl = 4'b0010; // AND
                    3'b110: ALUControl = (funct7_5) ? 4'b0110 : 4'b0011; // sh3add : OR
                    3'b100: ALUControl = 4'b1110; // XOR
                    
                    // --- Shifts ---
                    3'b001: ALUControl = 4'b1100; // SLL / SLLI
                    3'b101: ALUControl = (funct7_5) ? 4'b1111 : 4'b1101; // SRA(I) : SRL(I)

                    // --- Zba ---
                    3'b010: ALUControl = 4'b0100; // sh1add
                    // Note: sh2add is funct3 3'b100, but that conflicts with XOR. 
                    // In Zba, sh2add is often 3'b100 ONLY if funct7 is 0100000.
                    // For now, let's keep your XOR priority.
                    
                    default: ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
    
endmodule