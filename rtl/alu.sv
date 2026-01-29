module alu (
    input  logic [63:0] SrcA,        
    input  logic [63:0] SrcB,        
    input  logic [3:0]  ALUControl,  
    output logic [63:0] ALUResult,   
    output logic        Zero         
);

    // Zba Word Extraction: Extracts lower 32 bits and zero-extends
    logic [63:0] SrcA_uw;
    assign SrcA_uw = {32'b0, SrcA[31:0]};

    always_comb begin
        case (ALUControl)
            // --- Arithmetic & Logic ---
            4'b0000: ALUResult = SrcA + SrcB;           // ADD / ADDI
            4'b0001: ALUResult = SrcA - SrcB;           // SUB
            4'b0010: ALUResult = SrcA & SrcB;           // AND / ANDI
            4'b0011: ALUResult = SrcA | SrcB;           // OR / ORI
            4'b1110: ALUResult = SrcA ^ SrcB;           // XOR / XORI

            // --- Shift Operations ---
            4'b1100: ALUResult = SrcA << SrcB[5:0];               // SLL / SLLI
            4'b1101: ALUResult = SrcA >> SrcB[5:0];               // SRL / SRLI
            4'b1111: ALUResult = $signed(SrcA) >>> SrcB[5:0];     // SRA / SRAI

            // --- Zba (Shift-and-Add) ---
            4'b0100: ALUResult = SrcB + (SrcA << 1);    // sh1add 
            4'b0101: ALUResult = SrcB + (SrcA << 2);    // sh2add 
            4'b0110: ALUResult = SrcB + (SrcA << 3);    // sh3add 

            // --- Zba (Unsigned Word) ---
            4'b0111: ALUResult = SrcB + SrcA_uw;        // add.uw 
            4'b1000: ALUResult = SrcB + (SrcA_uw << 1); // sh1add.uw
            4'b1001: ALUResult = SrcB + (SrcA_uw << 2); // sh2add.uw
            4'b1010: ALUResult = SrcB + (SrcA_uw << 3); // sh3add.uw
            4'b1011: ALUResult = (SrcA_uw << SrcB[5:0]); // slli.uw 

            default: ALUResult = 64'b0;
        endcase
    end

    assign Zero = (ALUResult == 64'b0);

endmodule