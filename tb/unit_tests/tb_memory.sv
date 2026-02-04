`timescale 1ns/1ps

module tb_memory();
    logic        clk;
    logic [63:0] ALUResult_M;   // The address
    logic [63:0] WriteData_M;   // Data to store
    logic        MemWrite_M;    // Write enable
    logic [63:0] ReadData_M;    // Data output

    // Instantiate Data Memory module 
    memory dut (
        .clk(clk),
        .ALUResult_M(ALUResult_M),
        .WriteData_M(WriteData_M),
        .MemWrite_M(MemWrite_M),
        .ReadData_M(ReadData_M)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("memory_unit.vcd");
        $dumpvars(0, tb_memory);

        // Initialize
        clk = 0;
        ALUResult_M = 64'h0;
        WriteData_M = 64'h0;
        MemWrite_M = 0;

        #15; // Wait for reset period

        // --- Test 1: Store Doubleword (sd) ---
        // Address 0x10, Data 0xABCDE1234567890F
        ALUResult_M = 64'h10;
        WriteData_M = 64'hABCDE1234567890F;
        MemWrite_M  = 1;
        #10; // Trigger write on posedge
        MemWrite_M  = 0;
        $display("T1: Store complete at Address %h", ALUResult_M);

        // --- Test 2: Load Doubleword (ld) ---
        // Change address to something else, then back to 0x10
        ALUResult_M = 64'h0;
        #10;
        ALUResult_M = 64'h10; 
        #5; // Wait for combinational read
        $display("T2: Load Result = %h (Exp ABCDE1234567890F)", ReadData_M);

        // --- Test 3: Verify Memory ignores data when MemWrite is 0 ---
        WriteData_M = 64'h0000000000000000;
        MemWrite_M  = 0;
        #10;
        $display("T3: No-Write Check = %h (Exp ABCDE1234567890F)", ReadData_M);

        #20;
        $finish;
    end
endmodule