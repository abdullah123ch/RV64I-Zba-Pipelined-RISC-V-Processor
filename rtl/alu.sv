module alu (
    input  logic [63:0] SrcA,        // Operand A 
    input  logic [63:0] SrcB,        // Operand B 
    input  logic [3:0]  ALUControl,  // Control signal 
    output logic [63:0] ALUResult,   // 64-bit result
    output logic        Zero         // Zero flag for branching
);

    // Zba Word Extraction: Extracts the lower 32 bits and zero-extends to 64 bits
    logic [63:0] SrcA_uw;
    assign SrcA_uw = {32'b0, SrcA[31:0]};

    always @* begin

        case (ALUControl)
            4'b0000: ALUResult = SrcA + SrcB;           // ADD
            4'b0001: ALUResult = SrcA - SrcB;           // SUB
            4'b0010: ALUResult = SrcA & SrcB;           // AND
            4'b0011: ALUResult = SrcA | SrcB;           // OR

            // Shift-and-Add 
            4'b0100: ALUResult = SrcB + (SrcA << 1);    // sh1add 
            4'b0101: ALUResult = SrcB + (SrcA << 2);    // sh2add 
            4'b0110: ALUResult = SrcB + (SrcA << 3);    // sh3add 

            // Unsigned Word
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