// File: tb/unit_tests/tb_writeback.sv
// Brief: Unit testbench for Writeback stage result multiplexer.
// Tests selection of different result sources (ALU, Memory, PC+4) based on ResultSrc control.
// Validates correct data forwarding to register file and back to Decode stage.

`timescale 1ns/1ps

module tb_writeback();
    // ============================================================
    // INPUTS FROM MEM/WB PIPELINE REGISTER
    // ============================================================
    logic [63:0] ALUResult_W;                   // ALU result from Execute stage
    logic [63:0] ReadData_W;                    // memory read data from Memory stage
    logic [63:0] PCPlus4_W;                     // PC+4 value (for JAL/JALR return address)
    logic [1:0]  ResultSrc_W;                   // result source selector:
                                                // 00 = ALU result, 01 = memory data, 10 = PC+4
    
    // ============================================================
    // OUTPUT (to register file and back to Decode stage)
    // ============================================================
    logic [63:0] Result_W;                      // final multiplexed result for writeback

    // ============================================================
    // WRITEBACK STAGE INSTANTIATION
    // ============================================================
    // Instantiate writeback multiplexer (combinational logic)
    writeback dut (
        .ALUResult_W(ALUResult_W),              // ALU result input
        .ReadData_W(ReadData_W),                // memory read result input
        .PCPlus4_W(PCPlus4_W),                  // PC+4 input (return address)
        .ResultSrc_W(ResultSrc_W),              // result source selector
        .Result_W(Result_W)                     // final output to register file
    );

    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    initial begin
        // ============================================================
        // SETUP: VCD DUMP
        // ============================================================
        $dumpfile("writeback_unit.vcd");        // waveform capture file
        $dumpvars(0, tb_writeback);             // record all signals

        // ============================================================
        // TEST DATA INITIALIZATION
        // ============================================================
        // Pre-load different data values for each source
        ALUResult_W = 64'hAAAA_AAAA_AAAA_AAAA; // sample value: all 0xA's
        ReadData_W  = 64'hBBBB_BBBB_BBBB_BBBB; // sample value: all 0xB's
        PCPlus4_W   = 64'h0000_0000_0000_1004; // PC+4 example: 0x1004

        // ============================================================
        // TEST 1: SELECT ALU RESULT (ResultSrc = 00)
        // ============================================================
        // Most common case: ALU result written to register (arithmetic/logic ops)
        $display("[Writeback Unit Test: Result Source Selection]");
        $display("[%0t] TEST 1: ALU Result Selection (ResultSrc=00)", $time);
        $display("  - Expected: ALUResult_W = 0xAAAAAAAAAAAAAAAA");
        
        ResultSrc_W = 2'b00;                    // select ALU result
        #10;
        
        $display("  - Result_W = %h", Result_W);
        if (Result_W == 64'hAAAA_AAAA_AAAA_AAAA)
            $display("  >>> SUCCESS: Correct ALU result selected");
        else
            $display("  >>> FAILURE: Wrong result selected");

        // ============================================================
        // TEST 2: SELECT MEMORY RESULT (ResultSrc = 01)
        // ============================================================
        // Load instruction case: memory data written to register
        $display("[%0t] TEST 2: Memory Result Selection (ResultSrc=01)", $time);
        $display("  - Expected: ReadData_W = 0xBBBBBBBBBBBBBBBB (load result)");
        
        ResultSrc_W = 2'b01;                    // select memory read result
        #10;
        
        $display("  - Result_W = %h", Result_W);
        if (Result_W == 64'hBBBB_BBBB_BBBB_BBBB)
            $display("  >>> SUCCESS: Correct memory result selected");
        else
            $display("  >>> FAILURE: Wrong result selected");

        // ============================================================
        // TEST 3: SELECT PC+4 RESULT (ResultSrc = 10)
        // ============================================================
        // Jump instruction case (JAL/JALR): PC+4 (return address) written to register
        $display("[%0t] TEST 3: PC+4 Result Selection (ResultSrc=10)", $time);
        $display("  - Expected: PCPlus4_W = 0x0000000000001004 (return address)");
        
        ResultSrc_W = 2'b10;                    // select PC+4 (return address)
        #10;
        
        $display("  - Result_W = %h", Result_W);
        if (Result_W == 64'h0000_0000_0000_1004)
            $display("  >>> SUCCESS: Correct PC+4 result selected");
        else
            $display("  >>> FAILURE: Wrong result selected");

        // ============================================================
        // SIMULATION COMPLETION
        // ============================================================
        #10;
        $display("[%0t] Writeback unit test completed.", $time);
        $finish;
    end
endmodule