`timescale 1ns/1ps

module tb_decode();
    logic        clk;
    logic        rst;
    logic [31:0] Instr_D;
    logic [63:0] PC_D;
    logic [63:0] Result_W;
    logic [4:0]  Rd_W;
    logic        RegWrite_W;

    // Outputs
    logic [63:0] RD1_D, RD2_D, ImmExt_D;
    logic [4:0]  Rd_D;
    logic [63:0] PC_D_out;
    logic [1:0]  ResultSrc_D;
    logic        MemWrite_D, ALUSrc_D, RegWrite_D;
    logic [3:0]  ALUControl_D;

    // Instantiate Decode Stage
    decode dut (
        .* // Connects all signals with matching names
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("decode_unit.vcd");
        $dumpvars(0, tb_decode);

        // Initialize
        clk = 0; rst = 1;
        Instr_D = 32'h0; PC_D = 64'h100;
        Result_W = 64'hDEADBEEF; Rd_W = 5'd5; RegWrite_W = 0;

        #15 rst = 0;

        // --- Test 1: Write to Register File (Feedback from WB) ---
        // We simulate a previous instruction writing 0xDEADBEEF to x5
        RegWrite_W = 1; Rd_W = 5'd5; Result_W = 64'hA5A5A5A5;
        #10;
        RegWrite_W = 0;

        // --- Test 2: Decode I-Type (addi x10, x5, 100) ---
        // Op: 0010011, rd: 10, rs1: 5, imm: 100 (0x64)
        // Machine code: 06428513
        Instr_D = 32'h06428513;
        #10;
        $display("T2: addi | RD1=%h (Exp A5A5...), Imm=%d (Exp 100), RegWrite=%b", RD1_D, ImmExt_D, RegWrite_D);

        // --- Test 3: Decode Zba sh1add (sh1add x11, x5, x6) ---
        // Machine code: 2062a5b3
        Instr_D = 32'h2062a5b3;
        #10;
        $display("T3: sh1add | ALUControl=%b (Exp Zba op), RegWrite=%b", ALUControl_D, RegWrite_D);

        // --- Test 4: Decode S-Type (sd x5, 8(x2)) ---
        // Op: 0100011, rs2: 5, rs1: 2, imm: 8
        Instr_D = 32'h00513423;
        #10;
        $display("T4: sd | Imm=%d (Exp 8), MemWrite=%b, ALUSrc=%b", ImmExt_D, MemWrite_D, ALUSrc_D);

        #20;
        $finish;
    end
endmodule