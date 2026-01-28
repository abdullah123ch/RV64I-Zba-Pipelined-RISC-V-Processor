`timescale 1ns/1ps

module tb_execute();
    // Inputs from ID/EX Register
    logic [63:0] RD1_E, RD2_E, ImmExt_E, PC_E;
    logic [3:0]  ALUControl_E;
    logic        ALUSrc_E;
    
    // Outputs
    logic [63:0] ALUResult_E, WriteData_E, PCTarget_E;
    logic        Zero_E;

    // Instantiate Execute Stage
    execute dut (
        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .ImmExt_E(ImmExt_E),
        .PC_E(PC_E),
        .ALUControl_E(ALUControl_E),
        .ALUSrc_E(ALUSrc_E),
        .ALUResult_E(ALUResult_E),
        .WriteData_E(WriteData_E),
        .PCTarget_E(PCTarget_E),
        .Zero_E(Zero_E)
    );

    initial begin
        $dumpfile("execute_unit.vcd");
        $dumpvars(0, tb_execute);

        // Initialize values
        RD1_E = 64'd10;
        RD2_E = 64'd20;
        ImmExt_E = 64'd100;
        PC_E = 64'h1000;
        ALUControl_E = 4'b0000; // ADD
        ALUSrc_E = 0;           // Use RD2

        // --- Test 1: Standard Register Addition (ADD) ---
        // 10 + 20 = 30
        ALUControl_E = 4'b0000; ALUSrc_E = 0;
        #10;
        $display("T1: ADD (Reg)  | Result=%d (Exp 30)", ALUResult_E);

        // --- Test 2: Addition with Immediate (ADDI) ---
        // 10 + 100 = 110
        ALUSrc_E = 1;
        #10;
        $display("T2: ADDI (Imm) | Result=%d (Exp 110)", ALUResult_E);

        // --- Test 3: Zba sh1add Test ---
        // Calculation: (RD1 << 1) + RD2 => (10 << 1) + 20 = 40
        // Use your specific Zba ALUControl code (0100 based on your last log)
        ALUControl_E = 4'b0100; ALUSrc_E = 0;
        #10;
        $display("T3: sh1add     | Result=%d (Exp 40)", ALUResult_E);

        // --- Test 4: Branch Target Calculation ---
        // PC (0x1000) + Imm (100) = 0x1064
        #10;
        $display("T4: PCTarget   | Target=%h (Exp 1064)", PCTarget_E);

        // --- Test 5: Zero Flag (SUB) ---
        // 10 - 10 = 0
        RD1_E = 64'd10; RD2_E = 64'd10;
        ALUControl_E = 4'b0001; ALUSrc_E = 0; // SUB
        #10;
        $display("T5: Zero Flag  | Result=%d, Zero=%b (Exp 1)", ALUResult_E, Zero_E);

        #10;
        $finish;
    end
endmodule