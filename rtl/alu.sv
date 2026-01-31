module alu (
    input  logic [63:0] SrcA,        
    input  logic [63:0] SrcB,        
    input  logic [4:0]  ALUControl,  // 5-bit preserved for future expansion
    output logic [63:0] ALUResult,   
    output logic        Zero         
);

    // Helpers for Zba (Zero-extended word)
    logic [63:0] SrcA_uw;
    assign SrcA_uw = {32'b0, SrcA[31:0]};

    // Helpers for Word Instructions (Sign-extended result)
    logic [31:0] Res32;

    always_comb begin
        // --- Prevent Latches: Default Assignments ---
        ALUResult = 64'b0;
        Res32     = 32'b0; 

        case (ALUControl)
            // --- 64-bit Arithmetic & Logic ---
            5'b00000: ALUResult = SrcA + SrcB;           // ADD / ADDI
            5'b00001: ALUResult = SrcA - SrcB;           // SUB
            5'b00010: ALUResult = SrcA & SrcB;           // AND / ANDI
            5'b00011: ALUResult = SrcA | SrcB;           // OR / ORI
            5'b00100: ALUResult = SrcA ^ SrcB;           // XOR / XORI

            // --- 32-bit Word Operations (Sign-Extended) ---
            5'b01000: begin // ADDW / ADDIW
                Res32 = SrcA[31:0] + SrcB[31:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01001: begin // SUBW
                Res32 = SrcA[31:0] - SrcB[31:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end

            // --- Zba (Shift-and-Add) ---
            // Standard Addressing: Base + (Index << N)
            5'b10000: ALUResult = SrcB + (SrcA << 1);    // sh1add 
            5'b10001: ALUResult = SrcB + (SrcA << 2);    // sh2add 
            5'b10010: ALUResult = SrcB + (SrcA << 3);    // sh3add 

            // --- Zba (Unsigned Word) ---
            // Handles 32-bit indices in 64-bit address space
            5'b10011: ALUResult = SrcB + SrcA_uw;        // add.uw 
            5'b10100: ALUResult = SrcB + (SrcA_uw << 1); // sh1add.uw
            5'b10101: ALUResult = SrcB + (SrcA_uw << 2); // sh2add.uw
            5'b10110: ALUResult = SrcB + (SrcA_uw << 3); // sh3add.uw

            default:  ALUResult = 64'b0;
        endcase
    end

    assign Zero = (ALUResult == 64'b0);

endmodule