module MW_pipeline (
    input  logic        clk,
    input  logic        rst,
    
    // Data from Memory (M)
    input  logic [63:0] ALUResult_M,
    input  logic [63:0] ReadData_M,
    input  logic [4:0]  Rd_M,
    input  logic [63:0] PCPlus4_M,
    
    // Control from Memory (M)
    input  logic        RegWrite_M,
    input  logic [1:0]  ResultSrc_M,
    
    // Data to Writeback (W)
    output logic [63:0] ALUResult_W,
    output logic [63:0] ReadData_W,
    output logic [4:0]  Rd_W,
    output logic [63:0] PCPlus4_W,
    
    // Control to Writeback (W)
    output logic        RegWrite_W,
    output logic [1:0]  ResultSrc_W
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ALUResult_W <= 64'b0;
            ReadData_W  <= 64'b0;
            Rd_W        <= 5'b0;
            PCPlus4_W   <= 64'b0;
            RegWrite_W  <= 1'b0;
            ResultSrc_W <= 2'b0;
        end else begin
            ALUResult_W <= ALUResult_M;
            ReadData_W  <= ReadData_M;
            Rd_W        <= Rd_M;
            PCPlus4_W   <= PCPlus4_M;
            RegWrite_W  <= RegWrite_M;
            ResultSrc_W <= ResultSrc_M;
        end
    end

endmodule