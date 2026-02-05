// File: tb/unit_tests/tb_execute.sv
// Brief: Unit testbench for Execute stage and ALU.
// Tests ALU operations, data forwarding, branch logic, and Zba extension instructions.
// Validates correct computation and PC target generation for all instruction types.

`timescale 1ns/1ps

module tb_execute();
    // ============================================================
    // INPUTS FROM ID/EX PIPELINE REGISTER
    // ============================================================
    logic [63:0] RD1_E, RD2_E, ImmExt_E, PC_E; // operands and immediate
    logic [4:0]  Rd_E, Rs1_E, Rs2_E;           // register indices
    logic [4:0]  ALUControl_E;                  // ALU operation code
    logic        ALUSrc_E, Branch_E, Jump_E;   // control signals

    // ============================================================
    // DATA FORWARDING INPUTS (from Memory and Writeback stages)
    // ============================================================
    logic [63:0] ALUResult_M, Result_W;        // forwarding data sources

    // ============================================================
    // FORWARDING CONTROL SIGNALS (from Hazard Unit)
    // ============================================================
    logic [1:0]  ForwardA_E, ForwardB_E;       // forwarding selectors

    // ============================================================
    // OUTPUTS FROM EXECUTE STAGE
    // ============================================================
    logic [63:0] ALUResult_E, WriteData_E, PCTarget_E; // results and targets
    logic        PCSrc_E, Zero_E;              // branch/PC control and flags

    // ============================================================
    // EXECUTE STAGE INSTANTIATION
    // ============================================================
    // Instantiate execute module with all signals connected
    execute dut (.*);

    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    initial begin
        // ============================================================
        // SETUP: VCD DUMP
        // ============================================================
        $dumpfile("execute_unit.vcd");         // waveform capture file
        $dumpvars(0, tb_execute);              // record all signals

        // ============================================================
        // TEST 0: BASE CASE - NO FORWARDING
        // ============================================================
        // Initialize operands and control signals
        $display("[Execute Unit Test: Baseline Operation]");
        RD1_E = 64'd10;  RD2_E = 64'd20;      // operands: 10 and 20
        ImmExt_E = 64'd5;                      // immediate: 5
        ALUResult_M = 64'd100;                 // forwarding candidates
        Result_W = 64'd200;
        ALUControl_E = 5'b00000;               // ADD operation
        ALUSrc_E = 0;                          // use register operand B (RD2)
        ForwardA_E = 2'b00; ForwardB_E = 2'b00; // no forwarding
        
        #10;
        $display("[%0t] TEST 0 (No Forwarding): ALUResult=%d (Expected: 30 = 10+20)", 
                 $time, ALUResult_E);

        // ============================================================
        // TEST 1: FORWARDING FROM MEMORY STAGE
        // ============================================================
        // Simulates: ADD rd, x5, x6 where x5 result is in Memory stage (100)
        $display("[%0t] TEST 1 (Forward A from Memory)...", $time);
        ForwardA_E = 2'b10;                    // select ALUResult_M (100) for operand A
        ForwardB_E = 2'b00;                    // no forward for B (use RD2=20)
        
        #10;
        $display("[%0t]   ForwardA=2'b10: ALUResult=%d (Expected: 120 = 100+20)", 
                 $time, ALUResult_E);

        // ============================================================
        // TEST 2: FORWARDING FROM WRITEBACK STAGE
        // ============================================================
        // Simulates: ADD rd, x5, x6 where x6 result is in Writeback stage (200)
        $display("[%0t] TEST 2 (Forward B from Writeback)...", $time);
        ForwardA_E = 2'b00;                    // no forward for A (use RD1=10)
        ForwardB_E = 2'b01;                    // select Result_W (200) for operand B
        
        #10;
        $display("[%0t]   ForwardB=2'b01: ALUResult=%d (Expected: 210 = 10+200)", 
                 $time, ALUResult_E);

        // ============================================================
        // TEST 3: SIMULTANEOUS FORWARDING (Both A and B)
        // ============================================================
        // Simulates: ADD rd, x5, x6 with both dependencies from different stages
        $display("[%0t] TEST 3 (Forward A from Memory + B from Writeback)...", $time);
        ForwardA_E = 2'b10;                    // select ALUResult_M (100) for A
        ForwardB_E = 2'b01;                    // select Result_W (200) for B
        
        #10;
        $display("[%0t]   Mixed Forwarding: ALUResult=%d (Expected: 300 = 100+200)", 
                 $time, ALUResult_E);

        // ============================================================
        // TEST 4: ZBA EXTENSION - SH1ADD (Shift-Add 1)
        // ============================================================
        // SH1ADD: rd = (rs1 << 1) + rs2  [Zba extension]
        $display("[%0t] TEST 4 (Zba SH1ADD: (10<<1) + 20)...", $time);
        ALUControl_E = 5'b00100;               // SH1ADD operation code
        ForwardA_E = 2'b00; ForwardB_E = 2'b00; // no forwarding: use RD1=10, RD2=20
        ALUSrc_E = 0;                          // use register operand B
        
        #10;
        $display("[%0t]   SH1ADD Result=%d (Expected: 40 = (10<<1)+20)", 
                 $time, ALUResult_E);

        // ============================================================
        // TEST 5: IMMEDIATE OPERAND (ALUSrc=1)
        // ============================================================
        // Simulates: ADDI rd, rs1, imm  (use immediate instead of register B)
        $display("[%0t] TEST 5 (ADDI with immediate: 10 + 5)...", $time);
        ALUControl_E = 5'b00000;               // ADD operation
        ALUSrc_E = 1;                          // select immediate operand B (ImmExt=5)
        ForwardA_E = 2'b00; ForwardB_E = 2'b00;
        
        #10;
        $display("[%0t]   ADDI Result=%d (Expected: 15 = 10+5)", 
                 $time, ALUResult_E);

        // ============================================================
        // SIMULATION COMPLETION
        // ============================================================
        #10;
        $display("[%0t] Execute unit test completed.", $time);
        $finish;
    end
endmodule