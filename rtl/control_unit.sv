module control_unit (
    input  logic [6:3]  op,          // Instr[6:3] (Major Opcode)
    input  logic [2:0]  funct3,      // Instr[14:12]
    input  logic        funct7_5,    // Instr[30] (for sub/sra)
    input  logic        funct7_1,    // Instr[25] (Zba uses bit 25 sometimes)
    output logic [1:0]  ResultSrc,
    output logic        MemWrite,
    output logic        ALUSrc,
    output logic [2:0]  ImmSrc,
    output logic        RegWrite,
    output logic [3:0]  ALUControl
);

    logic [1:0] ALUOp;

    always_comb begin
        case (op)
            4'b0000: begin // lw / ld (Load)
                RegWrite  = 1'b1;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b0;
                ResultSrc = 2'b01;
                ALUOp     = 2'b00;
            end
            4'b0100: begin // sw / sd (Store)
                RegWrite  = 1'b0;
                ImmSrc    = 3'b001;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b1;
                ResultSrc = 2'b00;
                ALUOp     = 2'b00;
            end
            4'b0110: begin // R-type (ADD, SUB, and ZBA)
                RegWrite  = 1'b1;
                ImmSrc    = 3'bxxx;
                ALUSrc    = 1'b0;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00;
                ALUOp     = 2'b10;
            end
            4'b0010: begin // I-type ALU (addi)
                RegWrite  = 1'b1;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00;
                ALUOp     = 2'b10;
            end
            default: begin
                RegWrite  = 1'b0;
                ImmSrc    = 3'b000;
                ALUSrc    = 1'b0;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00;
                ALUOp     = 2'b00;
            end
        endcase
    end

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0000; // Addition (for Load/Store)
            2'b01: ALUControl = 4'b0001; // Subtraction (for Branch)
            
            2'b10: begin
                case (funct3)
                    3'b000: begin // add/sub
                        if (funct7_5) ALUControl = 4'b0001; // sub
                        else          ALUControl = 4'b0000; // add
                    end
                    // --- Zba Specific Opcodes (funct7 == 0100000 / 0x20) ---
                    3'b010: ALUControl = 4'b0100; // sh1add
                    3'b100: ALUControl = 4'b0101; // sh2add
                    3'b110: ALUControl = 4'b0110; // sh3add
                    
                    3'b111: ALUControl = 4'b0010; // and
                    3'b110: ALUControl = 4'b0011; // or
                    default: ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule