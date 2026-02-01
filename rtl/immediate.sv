module immediate (
    input  logic [31:0] Instr,    
    input  logic [2:0]  ImmSrc,   
    output logic [63:0] ImmExt    
);

    // Using separate wires for components makes it easier for Icarus Verilog
    logic [63:0] i_imm, s_imm, b_imm, u_imm, j_imm;

    assign i_imm = { {52{Instr[31]}}, Instr[31:20] };
    assign s_imm = { {52{Instr[31]}}, Instr[31:25], Instr[11:7] };
    assign b_imm = { {51{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0 };
    assign u_imm = { {32{Instr[31]}}, Instr[31:12], 12'b0 };
    assign j_imm = { {43{Instr[31]}}, Instr[31], Instr[19:12], Instr[20], Instr[30:21], 1'b0 };

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