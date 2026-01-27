module EM_pipeline (
    input  logic        clk,
    input  logic        rst,
    
    // Data from Execute (E)
    input  logic [63:0] ALUResult_E,
    input  logic [63:0] WriteData_E, 
    input  logic [4:0]  Rd_E,
    input  logic [63:0] PCPlus4_E,   
    
    // Control from Execute (E)
    input  logic        RegWrite_E,
    input  logic [1:0]  ResultSrc_E,
    input  logic        MemWrite_E,
    
    // Data to Memory (M)
    output logic [63:0] ALUResult_M,
    output logic [63:0] WriteData_M,
    output logic [4:0]  Rd_M,
    output logic [63:0] PCPlus4_M,
    
    // Control to Memory (M)
    output logic        RegWrite_M,
    output logic [1:0]  ResultSrc_M,
    output logic        MemWrite_M
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ALUResult_M <= 64'b0;
            WriteData_M <= 64'b0;
            Rd_M        <= 5'b0;
            PCPlus4_M   <= 64'b0;
            RegWrite_M  <= 1'b0;
            ResultSrc_M <= 2'b0;
            MemWrite_M  <= 1'b0;
        end else begin
            ALUResult_M <= ALUResult_E;
            WriteData_M <= WriteData_E;
            Rd_M        <= Rd_E;
            PCPlus4_M   <= PCPlus4_E;
            RegWrite_M  <= RegWrite_E;
            ResultSrc_M <= ResultSrc_E;
            MemWrite_M  <= MemWrite_E;
        end
    end

endmodule