module alu (
    input  logic [63:0] SrcA, SrcB,
    input  logic [4:0]  ALUControl,
    output logic [63:0] ALUResult,
    output logic        Zero
);
    // 1. Static Slicing & Pre-calculation
    wire [31:0] a32 = SrcA[31:0];
    wire [31:0] b32 = SrcB[31:0];
    wire [63:0] a_uw = {32'b0, a32}; // Locked Zero-Extension for Zba

    wire [31:0] sum32 = a32 + b32;
    wire [31:0] sub32 = a32 - b32;
    wire [31:0] sll32 = a32 << SrcB[4:0];
    wire [31:0] srl32 = a32 >> SrcB[4:0];
    wire [31:0] sra32 = $signed(a32) >>> SrcB[4:0];

    

    // 2. Result Selection (Zero math inside here)
    always_comb begin
        case (ALUControl)
            // 64-bit Basic
            5'b00000: ALUResult = SrcA + SrcB;
            5'b00001: ALUResult = SrcA - SrcB;
            5'b00010: ALUResult = SrcA & SrcB;
            5'b00011: ALUResult = SrcA | SrcB;
            5'b00100: ALUResult = SrcA ^ SrcB;

            // Word Ops (Sign-Extended)
            5'b01000: ALUResult = {{32{sum32[31]}}, sum32}; 
            5'b01001: ALUResult = {{32{sub32[31]}}, sub32}; 
            5'b01100: ALUResult = {{32{sll32[31]}}, sll32}; 
            5'b01101: ALUResult = {{32{srl32[31]}}, srl32};  
            5'b01110: ALUResult = {{32{sra32[31]}}, sra32};  

            // Inside alu.sv case statement
            // Standard Zba (Typically 64-bit R-type, funct7 bit 29 is 1)
            5'b10000: ALUResult = SrcB + (SrcA << 1);    // sh1add
            5'b10001: ALUResult = SrcB + (SrcA << 2);    // sh2add
            5'b10010: ALUResult = SrcB + (SrcA << 3);    // sh3add

            // Zba .UW (Typically Word R-type, funct7 bit 25 is 1)
            5'b10011: ALUResult = SrcB + a_uw;               // add.uw
            5'b10100: ALUResult = SrcB + (a_uw << 1);        // sh1add.uw
            5'b10101: ALUResult = SrcB + (a_uw << 2);        // sh2add.uw
            5'b10110: ALUResult = SrcB + (a_uw << 3);        // sh3add.uw

            // Comparisons
            5'b01010: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 64'd1 : 64'd0;
            5'b01011: ALUResult = (SrcA < SrcB) ? 64'd1 : 64'd0;

            default:  ALUResult = 64'b0;
        endcase
    end

    assign Zero = (ALUResult == 64'b0);
endmodule