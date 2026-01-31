module alu (
    input  logic [63:0] SrcA,        
    input  logic [63:0] SrcB,        
    input  logic [4:0]  ALUControl,
    output logic [63:0] ALUResult,   
    output logic        Zero         
);

    // Helpers for Zba (Zero-extended word)
    logic [63:0] SrcA_uw;
    assign SrcA_uw = {32'b0, SrcA[31:0]};

    // Helpers for Word Instructions (Sign-extended result)
    logic [31:0] Res32;

    always_comb begin
        case (ALUControl)
            // --- 64-bit Arithmetic & Logic ---
            5'b00000: ALUResult = SrcA + SrcB;           // ADD / ADDI
            5'b00001: ALUResult = SrcA - SrcB;           // SUB
            5'b00010: ALUResult = SrcA & SrcB;           // AND / ANDI
            5'b00011: ALUResult = SrcA | SrcB;           // OR / ORI
            5'b00100: ALUResult = SrcA ^ SrcB;           // XOR / XORI

            // --- 64-bit Shift Operations ---
            5'b00101: ALUResult = SrcA << SrcB[5:0];               // SLL / SLLI
            5'b00110: ALUResult = SrcA >> SrcB[5:0];               // SRL / SRLI
            5'b00111: ALUResult = $signed(SrcA) >>> SrcB[5:0];     // SRA / SRAI

            // --- 32-bit Word Operations (RV64I "W" Extension) ---
            // These perform 32-bit math and SIGN-EXTEND the result to 64-bit
            5'b01000: begin // ADDW / ADDIW
                Res32 = SrcA[31:0] + SrcB[31:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01001: begin // SUBW
                Res32 = SrcA[31:0] - SrcB[31:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01010: begin // SLLW / SLLIW
                Res32 = SrcA[31:0] << SrcB[4:0]; 
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01011: begin // SRLW / SRLIW
                Res32 = SrcA[31:0] >> SrcB[4:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01100: begin // SRAW / SRAIW
                Res32 = $signed(SrcA[31:0]) >>> SrcB[4:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end

            // --- Zba (Shift-and-Add) ---
            5'b10000: ALUResult = SrcB + (SrcA << 1);    // sh1add 
            5'b10001: ALUResult = SrcB + (SrcA << 2);    // sh2add 
            5'b10010: ALUResult = SrcB + (SrcA << 3);    // sh3add 

            // --- Zba (Unsigned Word) ---
            5'b10011: ALUResult = SrcB + SrcA_uw;        // add.uw 
            5'b10100: ALUResult = SrcB + (SrcA_uw << 1); // sh1add.uw
            5'b10101: ALUResult = SrcB + (SrcA_uw << 2); // sh2add.uw
            5'b10110: ALUResult = SrcB + (SrcA_uw << 3); // sh3add.uw
            5'b10111: ALUResult = (SrcA_uw << SrcB[5:0]); // slli.uw 

            default:  ALUResult = 64'b0;
        endcase
    end

    assign Zero = (ALUResult == 64'b0);

endmodule