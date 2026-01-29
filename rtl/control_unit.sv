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
        // --- Default Assignments to prevent Latches ---
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
            4'b0110: begin // R-type (ADD, SUB, and ZBA)
                RegWrite  = 1'b1;
                ALUOp     = 2'b10;
            end
            4'b0010: begin // I-type ALU (addi)
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
                ResultSrc = 2'b10;  // PC+4 to Register File
                Jump      = 1'b1;   
            end
            default: ; // Use defaults set above
        endcase
    end

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0000; // Addition
            2'b01: ALUControl = 4'b0001; // Subtraction
            2'b10: begin
                case (funct3)
                    3'b000: ALUControl = (funct7_5) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b111: ALUControl = 4'b0010; // AND
                    3'b110: ALUControl = 4'b0011; // OR
                    3'b010: ALUControl = 4'b0100; // sh1add
                    3'b100: ALUControl = 4'b0101; // sh2add
                    3'b110: ALUControl = 4'b0110; // sh3add (Note: overlap with OR if not careful with funct7)
                    default: ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule