`timescale 1ns/1ps

module tb_writeback();
    // Inputs to Writeback Stage
    logic [63:0] ALUResult_W;
    logic [63:0] ReadData_W;
    logic [63:0] PCPlus4_W;
    logic [1:0]  ResultSrc_W;
    
    // Output
    logic [63:0] Result_W;

    // Instantiate Writeback Stage
    writeback dut (
        .ALUResult_W(ALUResult_W),
        .ReadData_W(ReadData_W),
        .PCPlus4_W(PCPlus4_W),
        .ResultSrc_W(ResultSrc_W),
        .Result_W(Result_W)
    );

    initial begin
        $dumpfile("writeback_unit.vcd");
        $dumpvars(0, tb_writeback);

        // Initialize dummy data
        ALUResult_W = 64'hAAAA_AAAA_AAAA_AAAA; // Result from Execute
        ReadData_W  = 64'hBBBB_BBBB_BBBB_BBBB; // Result from Memory
        PCPlus4_W   = 64'h0000_0000_0000_1004; // Result from Fetch (JAL)

        // --- Test 1: Select ALU Result (ResultSrc = 00) ---
        ResultSrc_W = 2'b00;
        #10;
        $display("T1: ALU Select  | Result=%h (Exp AAAA...)", Result_W);

        // --- Test 2: Select Memory Result (ResultSrc = 01) ---
        ResultSrc_W = 2'b01;
        #10;
        $display("T2: Mem Select  | Result=%h (Exp BBBB...)", Result_W);

        // --- Test 3: Select PC+4 Result (ResultSrc = 10) ---
        ResultSrc_W = 2'b10;
        #10;
        $display("T3: PC+4 Select | Result=%h (Exp 1004)", Result_W);

        #10;
        $finish;
    end
endmodule