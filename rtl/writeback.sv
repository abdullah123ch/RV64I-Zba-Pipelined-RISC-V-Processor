module writeback (
    // Data Inputs from MEM/WB Register
    input  logic [63:0] ALUResult_W,
    input  logic [63:0] ReadData_W,
    input  logic [63:0] PCPlus4_W,
    
    // Control Input from MEM/WB Register
    input  logic [1:0]  ResultSrc_W, // 00: ALU, 01: Memory, 10: PC+4
    
    // Final Output to be sent back to the Decode Stage
    output logic [63:0] Result_W
);

    always_comb begin
        case (ResultSrc_W)
            2'b00:   Result_W = ALUResult_W;
            2'b01:   Result_W = ReadData_W;
            2'b10:   Result_W = PCPlus4_W;
            default: Result_W = 64'b0;
        endcase
    end

endmodule