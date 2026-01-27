module immediate (
    input  logic [31:0] Instr,    // 32-bit instruction
    input  logic [2:0]  ImmSrc,   // Control signal from Control Unit
    output logic [63:0] ImmExt    // 64-bit sign-extended immediate
);

    always_comb begin
        case (ImmSrc)
            // I-type: ALU immediates, Loads (12-bit)
            3'b000: ImmExt = {{52{Instr[31]}}, Instr[31:20]};
            
            // S-type: Stores (12-bit)
            3'b001: ImmExt = {{52{Instr[31]}}, Instr[31:25], Instr[11:7]};
            
            // B-type: Branches (13-bit, bit 0 is always 0)
            3'b010: ImmExt = {{51{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            
            // U-type: LUI, AUIPC (20-bit, shifted left 12, sign-extended to 64)
            3'b011: ImmExt = {{32{Instr[31]}}, Instr[31:12], 12'b0};
            
            // J-type: Jumps (21-bit, bit 0 is always 0)
            3'b100: ImmExt = {{43{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0};
            
            default: ImmExt = 64'b0;
        endcase
    end

endmodule