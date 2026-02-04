module alu (
    input  logic [63:0] SrcA, SrcB,
    input  logic [4:0]  ALUControl,
    output logic [63:0] ALUResult,
    output logic        Zero
);
    // 1. Prepare Word Inputs
    wire [31:0] a32 = SrcA[31:0];
    wire [31:0] b32 = SrcB[31:0];
    wire [63:0] a_uw = {32'b0, a32}; // Zero-Extension for Zba

    // 2. Pre-calculate Word Results (Sign Extended)
    wire [31:0] sum32 = a32 + b32;
    wire [31:0] sub32 = a32 - b32;
    wire [31:0] sll32 = a32 << SrcB[4:0];
    wire [31:0] srl32 = a32 >> SrcB[4:0];
    wire [31:0] sra32 = $signed(a32) >>> SrcB[4:0];

    // 3. Explicit Zba Shifted Wires (Force 64-bit precision)
    wire [63:0] sh1_a = SrcA << 1;
    wire [63:0] sh2_a = SrcA << 2;
    wire [63:0] sh3_a = SrcA << 3;

    wire [63:0] sh1_auw = a_uw << 1;
    wire [63:0] sh2_auw = a_uw << 2;
    wire [63:0] sh3_auw = a_uw << 3;

    // 4. Final Result Selection
    always_comb begin
        case (ALUControl)
            // 64-bit Basic
            5'b00000: ALUResult = SrcA + SrcB;
            5'b00001: ALUResult = SrcA - SrcB;
            5'b00010: ALUResult = SrcA & SrcB;
            5'b00011: ALUResult = SrcA | SrcB;
            5'b00100: ALUResult = SrcA ^ SrcB;
            5'b00101: ALUResult = SrcA << SrcB[5:0];
            5'b00110: ALUResult = SrcA >> SrcB[5:0];
            5'b00111: ALUResult = $signed(SrcA) >>> SrcB[5:0];

            // Word Ops (Sign-Extended)
            5'b01000: ALUResult = {{32{sum32[31]}}, sum32}; 
            5'b01001: ALUResult = {{32{sub32[31]}}, sub32}; 
            5'b01100: ALUResult = {{32{sll32[31]}}, sll32}; 
            5'b01101: ALUResult = {{32{srl32[31]}}, srl32};  
            5'b01110: ALUResult = {{32{sra32[31]}}, sra32};  

            // Zba Standard (Explicit wires used here)
            5'b10000: ALUResult = SrcB + sh1_a;   // sh1add
            5'b10001: ALUResult = SrcB + sh2_a;   // sh2add
            5'b10010: ALUResult = SrcB + sh3_a;   // sh3add

            // Zba .UW Zero-Extended (Explicit wires used here)
            5'b10011: ALUResult = SrcB + a_uw;    // add.uw
            5'b10100: ALUResult = SrcB + sh1_auw; // sh1add.uw
            5'b10101: ALUResult = SrcB + sh2_auw; // sh2add.uw
            5'b10110: ALUResult = SrcB + sh3_auw; // sh3add.uw

            // Comparisons
            5'b01010: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 64'd1 : 64'd0;
            5'b01011: ALUResult = (SrcA < SrcB) ? 64'd1 : 64'd0;

            default:  ALUResult = 64'b0;
        endcase
    end

    assign Zero = (ALUResult == 64'b0);
endmodule