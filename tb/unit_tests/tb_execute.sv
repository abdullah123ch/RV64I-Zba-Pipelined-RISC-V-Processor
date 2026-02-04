`timescale 1ns/1ps

module tb_execute();
    // Inputs from ID/EX Pipeline Register
    logic [63:0] RD1_E, RD2_E, ImmExt_E, PC_E;
    logic [4:0]  Rd_E, Rs1_E, Rs2_E;
    logic [4:0]  ALUControl_E;
    logic        ALUSrc_E, Branch_E, Jump_E;

    // Forwarding Data Inputs (from Memory and Writeback stages)
    logic [63:0] ALUResult_M, Result_W;

    // Forwarding Control Signals (from Hazard Unit)
    logic [1:0]  ForwardA_E, ForwardB_E;

    // Outputs
    logic [63:0] ALUResult_E, WriteData_E, PCTarget_E;
    logic        PCSrc_E, Zero_E;

    // Instantiate Execute Stage
    execute dut (.*);

    initial begin
        $dumpfile("execute_unit.vcd");
        $dumpvars(0, tb_execute);

        // --- Initial State (No Hazards) ---
        RD1_E = 64'd10;  RD2_E = 64'd20;  ImmExt_E = 64'd5;
        ALUResult_M = 64'd100; Result_W = 64'd200;
        ALUControl_E = 5'b00000 ; // ADD
        ALUSrc_E = 0; ForwardA_E = 2'b00; ForwardB_E = 2'b00;
        #10;
        $display("[%0t] No Forward: Result=%d (Exp 30)", $time, ALUResult_E);

        // --- TEST 1: Forwarding A from Memory (Priority) ---
        // Simulates: add rd, x5, x6 where x5 was just calculated
        ForwardA_E = 2'b10; // Select ALUResult_M (100)
        #10;
        $display("[%0t] FwdA (MEM): Result=%d (Exp 120)", $time, ALUResult_E);

        // --- TEST 2: Forwarding B from Writeback ---
        // Simulates: add rd, x5, x6 where x6 is in Writeback stage
        ForwardA_E = 2'b00; ForwardB_E = 2'b01; // Select Result_W (200)
        #10;
        $display("[%0t] FwdB (WB): Result=%d (Exp 210)", $time, ALUResult_E);

        // --- TEST 3: Simultaneous Forwarding (MEM and WB) ---
        ForwardA_E = 2'b10; ForwardB_E = 2'b01;
        #10;
        $display("[%0t] Mixed Fwd: Result=%d (Exp 300)", $time, ALUResult_E);

        // --- TEST 4: Zba Extension (sh1add) ---
        // ALUControl 0100 (assuming this is your sh1add mapping)
        ALUControl_E = 5'b00100; 
        ForwardA_E = 2'b00; ForwardB_E = 2'b00; // Back to 10 and 20
        #10;
        $display("[%0t] sh1add: Result=%d (Exp 40: 20 + (10<<1))", $time, ALUResult_E);

        #10;
        $finish;
    end
endmodule