module DE_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic        clr,
    
    // Data Signals from Decode (D)
    input  logic [63:0] RD1_D, RD2_D, PC_D, ImmExt_D,
    input  logic [4:0]  Rd_D, Rs1_D, Rs2_D,
    
    // Control Signals from Decode (D)
    input  logic        RegWrite_D, MemWrite_D, ALUSrc_D, Branch_D, Jump_D,
    input  logic [1:0]  ResultSrc_D,
    input  logic [4:0]  ALUControl_D,
    input  logic [2:0]  funct3_D,
    input  logic        is_jalr_D,   // NEW: Signal from Control Unit

    // Data Signals to Execute (E)
    output logic [63:0] RD1_E, RD2_E, PC_E, ImmExt_E,
    output logic [4:0]  Rd_E, Rs1_E, Rs2_E,
    
    // Control Signals to Execute (E)
    output logic        RegWrite_E, MemWrite_E, ALUSrc_E, Branch_E, Jump_E,
    output logic [1:0]  ResultSrc_E,
    output logic [4:0]  ALUControl_E,
    output logic [2:0]  funct3_E,
    output logic        is_jalr_E    // NEW: Passed to Execute Stage
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || clr) begin
            RD1_E        <= 64'b0;
            RD2_E        <= 64'b0;
            PC_E         <= 64'b0;
            ImmExt_E     <= 64'b0;
            Rd_E         <= 5'b0;
            Rs1_E        <= 5'b0;
            Rs2_E        <= 5'b0;
            RegWrite_E   <= 1'b0;
            ResultSrc_E  <= 2'b00;
            MemWrite_E   <= 1'b0;
            ALUControl_E <= 5'b0;
            ALUSrc_E     <= 1'b0;
            Branch_E     <= 1'b0;
            Jump_E       <= 1'b0;
            funct3_E     <= 3'b0;
            is_jalr_E    <= 1'b0;    // Clear on reset/flush
        end else begin
            RD1_E        <= RD1_D;
            RD2_E        <= RD2_D;
            PC_E         <= PC_D;
            ImmExt_E     <= ImmExt_D;
            Rd_E         <= Rd_D;
            Rs1_E        <= Rs1_D;
            Rs2_E        <= Rs2_D;
            RegWrite_E   <= RegWrite_D;
            ResultSrc_E  <= ResultSrc_D;
            MemWrite_E   <= MemWrite_D;
            ALUControl_E <= ALUControl_D;
            ALUSrc_E     <= ALUSrc_D;
            Branch_E     <= Branch_D;
            Jump_E       <= Jump_D;
            funct3_E     <= funct3_D;
            is_jalr_E    <= is_jalr_D; // Propagate
        end
    end

endmodule