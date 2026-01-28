module DE_pipeline (
    input  logic        clk,
    input  logic        rst,
    
    // Data Signals from Decode (D)
    input  logic [63:0] RD1_D,
    input  logic [63:0] RD2_D,
    input  logic [63:0] PC_D,
    input  logic [63:0] ImmExt_D,
    input  logic [4:0]  Rd_D,
    
    // Control Signals from Decode (D)
    input  logic        RegWrite_D,
    input  logic [1:0]  ResultSrc_D,
    input  logic        MemWrite_D,
    input  logic [3:0]  ALUControl_D,
    input  logic        ALUSrc_D,
    input  logic        Branch_D,     
    input  logic        Jump_D,

    // Data Signals to Execute (E)
    output logic [63:0] RD1_E,
    output logic [63:0] RD2_E,
    output logic [63:0] PC_E,
    output logic [63:0] ImmExt_E,
    output logic [4:0]  Rd_E,
    
    // Control Signals to Execute (E)
    output logic        RegWrite_E,
    output logic [1:0]  ResultSrc_E,
    output logic        MemWrite_E,
    output logic [3:0]  ALUControl_E,
    output logic        ALUSrc_E,
    output logic        Branch_E, 
    output logic        Jump_E
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Clear all data and control paths on reset
            RD1_E        <= 64'b0;
            RD2_E        <= 64'b0;
            PC_E         <= 64'b0;
            ImmExt_E     <= 64'b0;
            Rd_E         <= 5'b0;
            RegWrite_E   <= 1'b0;
            ResultSrc_E  <= 2'b0;
            MemWrite_E   <= 1'b0;
            ALUControl_E <= 4'b0;
            ALUSrc_E     <= 1'b0;
            Branch_E     <= 1'b0;
            Jump_E       <= 1'b0;
        end else begin
            RD1_E        <= RD1_D;
            RD2_E        <= RD2_D;
            PC_E         <= PC_D;
            ImmExt_E     <= ImmExt_D;
            Rd_E         <= Rd_D;
            RegWrite_E   <= RegWrite_D;
            ResultSrc_E  <= ResultSrc_D;
            MemWrite_E   <= MemWrite_D;
            ALUControl_E <= ALUControl_D;
            ALUSrc_E     <= ALUSrc_D;
            Branch_E     <= Branch_D;
            Jump_E       <= Jump_D;
        end
    end

endmodule