module immediate (
    input  logic [31:0] Instr,    
    input  logic [2:0]  ImmSrc,   
    output logic [63:0] ImmExt    
);

    always @* begin // Using always_comb is preferred for SystemVerilog
        case (ImmSrc)
            // I-type: ADDI, LD, JALR (12-bit)
            3'b000: ImmExt = {{52{Instr[31]}}, Instr[31:20]};
            
            // S-type: SD (12-bit)
            3'b001: ImmExt = {{52{Instr[31]}}, Instr[31:25], Instr[11:7]};
            
            // B-type: BEQ, BNE (13-bit) 
            // Corrected: {{51{Instr[31]}}, ...}
            3'b010: ImmExt = {{51{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            
            // U-type: LUI, AUIPC
            3'b011: ImmExt = {{32{Instr[31]}}, Instr[31:12], 12'b0};
            
            // J-type: JAL (21-bit)
            // Corrected: {{43{Instr[31]}}, ...}
            3'b100: ImmExt = {{43{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0};
            
            default: ImmExt = 64'b0;
        endcase
    end

endmodule