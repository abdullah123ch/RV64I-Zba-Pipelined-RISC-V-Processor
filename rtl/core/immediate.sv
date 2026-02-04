module immediate (
    input  logic [31:0] Instr,    
    input  logic [2:0]  ImmSrc,   
    output logic [63:0] ImmExt    
);
    // 1. I-type: 12-bit immediate
    wire [63:0] i_imm = { {52{Instr[31]}}, Instr[31:20] };

    // 2. S-type: 12-bit (Store offsets)
    wire [63:0] s_imm = { {52{Instr[31]}}, Instr[31:25], Instr[11:7] };

    // 3. B-type: 13-bit (Branch offsets - bit 0 is always 0)
    wire [63:0] b_imm = { {51{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0 };

    // 4. U-type: 32-bit (LUI/AUIPC - Upper 20 bits)
    wire [63:0] u_imm = { {32{Instr[31]}}, Instr[31:12], 12'b0 };

    // 5. J-type: 21-bit (JAL - Scrambled immediate)
    // Format: Instr[31] (sign) | Instr[19:12] | Instr[20] | Instr[30:21] | 0
    wire [63:0] j_imm = { {43{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0 };

    

    always_comb begin
        case (ImmSrc)
            3'b000:  ImmExt = i_imm;
            3'b001:  ImmExt = s_imm;
            3'b010:  ImmExt = b_imm;
            3'b011:  ImmExt = u_imm;
            3'b100:  ImmExt = j_imm;
            default: ImmExt = 64'b0;
        endcase
    end
endmodule