module alu (
    input  logic [63:0] SrcA,        
    input  logic [63:0] SrcB,        
    input  logic [4:0]  ALUControl,  
    output logic [63:0] ALUResult,   
    output logic        Zero         
);

    // Helpers
    logic [63:0] SrcA_uw;
    assign SrcA_uw = {32'b0, SrcA[31:0]};
    
    logic [5:0]  shamt64; // 6 bits for 64-bit shifts (0-63)
    logic [4:0]  shamt32; // 5 bits for 32-bit shifts (0-31)
    assign shamt64 = SrcB[5:0];
    assign shamt32 = SrcB[4:0];

    logic [31:0] Res32;

    always_comb begin
        ALUResult = 64'b0;
        Res32     = 32'b0; 

        case (ALUControl)
            // --- Arithmetic & Logic ---
            5'b00000: ALUResult = SrcA + SrcB;           
            5'b00001: ALUResult = SrcA - SrcB;           
            5'b00010: ALUResult = SrcA & SrcB;           
            5'b00011: ALUResult = SrcA | SrcB;           
            5'b00100: ALUResult = SrcA ^ SrcB;           

            // --- 64-bit Shits ---
            5'b00101: ALUResult = SrcA <<  shamt64;                 // SLL/SLLI
            5'b00110: ALUResult = SrcA >>  shamt64;                 // SRL/SRLI
            5'b00111: ALUResult = $signed(SrcA) >>> shamt64;        // SRA/SRAI

            // --- Comparisons ---
            5'b01010: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 64'b1 : 64'b0; // SLT/SLTI
            5'b01011: ALUResult = (SrcA < SrcB) ? 64'b1 : 64'b0;                   // SLTU/SLTIU

            // --- 32-bit Word Operations (Sign-Extended) ---
            5'b01000: begin // ADDW/ADDIW
                Res32 = SrcA[31:0] + SrcB[31:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01001: begin // SUBW
                Res32 = SrcA[31:0] - SrcB[31:0];
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01100: begin // SLLW/SLLIW
                Res32 = SrcA[31:0] << shamt32;
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01101: begin // SRLW/SRLIW
                Res32 = SrcA[31:0] >> shamt32;
                ALUResult = {{32{Res32[31]}}, Res32};
            end
            5'b01110: begin // SRAW/SRAIW
                Res32 = $signed(SrcA[31:0]) >>> shamt32;
                ALUResult = {{32{Res32[31]}}, Res32};
            end

            // --- Zba ---
            5'b10000: ALUResult = SrcB + (SrcA << 1);    
            5'b10001: ALUResult = SrcB + (SrcA << 2);    
            5'b10010: ALUResult = SrcB + (SrcA << 3);    
            5'b10011: ALUResult = SrcB + SrcA_uw;        
            5'b10100: ALUResult = SrcB + (SrcA_uw << 1); 
            5'b10101: ALUResult = SrcB + (SrcA_uw << 2); 
            5'b10110: ALUResult = SrcB + (SrcA_uw << 3); 

            default:  ALUResult = 64'b0;
        endcase
    end

    assign Zero = (ALUResult == 64'b0);

endmodule