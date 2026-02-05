// File: tb/unit_tests/tb_memory.sv
// Brief: Unit testbench for Memory stage (data memory interface).
// Tests load and store operations, memory read/write synchronization,
// and correct data retrieval from data RAM.

`timescale 1ns/1ps

module tb_memory();
    // ============================================================
    // MEMORY STAGE SIGNALS
    // ============================================================
    logic        clk;                           // system clock (for synchronous writes)
    logic [63:0] ALUResult_M;                   // memory address (from ALU result)
    logic [63:0] WriteData_M;                   // data to write (store operand)
    logic        MemWrite_M;                    // write enable: 1=store, 0=load
    logic [63:0] ReadData_M;                    // data read from memory (load result)

    // ============================================================
    // MEMORY MODULE INSTANTIATION
    // ============================================================
    // Instantiate data memory with synchronous write and asynchronous read
    memory dut (
        .clk(clk),                              // system clock for write operations
        .ALUResult_M(ALUResult_M),              // memory address
        .WriteData_M(WriteData_M),              // write data for store operations
        .MemWrite_M(MemWrite_M),                // write enable control
        .ReadData_M(ReadData_M)                 // read data output for load operations
    );

    // ============================================================
    // CLOCK GENERATION (100MHz)
    // ============================================================
    always #5 clk = ~clk;

    // ============================================================
    // TEST SEQUENCE
    // ============================================================
    initial begin
        // ============================================================
        // SETUP: VCD DUMP
        // ============================================================
        $dumpfile("memory_unit.vcd");           // waveform capture file
        $dumpvars(0, tb_memory);                // record all signals

        // ============================================================
        // INITIALIZATION
        // ============================================================
        clk = 0;                                // start clock low
        ALUResult_M = 64'h0;                    // address: 0
        WriteData_M = 64'h0;                    // write data: 0
        MemWrite_M = 0;                         // write disabled (read mode)

        #15;                                     // wait 15ns (settling time)

        // ============================================================
        // TEST 1: STORE DOUBLEWORD (SD) - WRITE OPERATION
        // ============================================================
        // Test storing 64-bit value to memory at address 0x10
        $display("[%0t] TEST 1: Store Doubleword (SD) Operation", $time);
        $display("  - Writing value 0xABCDE1234567890F to address 0x10");
        
        ALUResult_M = 64'h10;                   // set memory address to 0x10
        WriteData_M = 64'hABCDE1234567890F;    // set data to store
        MemWrite_M  = 1;                        // enable write
        
        #10;                                     // wait for clock edge (synchronous write)
        MemWrite_M  = 0;                        // disable write
        $display("  - Store operation initiated at address %h", ALUResult_M);

        // ============================================================
        // TEST 2: LOAD DOUBLEWORD (LD) - READ OPERATION
        // ============================================================
        // Test loading stored data back from memory
        $display("[%0t] TEST 2: Load Doubleword (LD) Operation", $time);
        $display("  - Reading from address 0x10 (previously stored)");
        
        ALUResult_M = 64'h0;                    // change address temporarily
        #10;
        
        ALUResult_M = 64'h10;                   // set address back to 0x10
        #5;                                      // wait for combinational read to settle
        
        $display("  - Load Result: %h (Expected: ABCDE1234567890F)", ReadData_M);
        if (ReadData_M == 64'hABCDE1234567890F)
            $display("  >>> SUCCESS: Read data matches written data");
        else
            $display("  >>> FAILURE: Read data does not match");

        // ============================================================
        // TEST 3: WRITE DISABLE CHECK - READ PRESERVES DATA
        // ============================================================
        // Verify that MemWrite_M=0 prevents data corruption
        $display("[%0t] TEST 3: Write Disable (No-Write Check)", $time);
        $display("  - Attempting write with MemWrite_M=0 (should not modify memory)");
        
        WriteData_M = 64'h0000000000000000;     // attempt to write zeros
        MemWrite_M  = 0;                        // but write is disabled
        
        #10;                                     // wait for clock edge
        
        $display("  - Read after disabled write: %h (Expected: ABCDE1234567890F)", ReadData_M);
        if (ReadData_M == 64'hABCDE1234567890F)
            $display("  >>> SUCCESS: Data preserved (write was ignored)");
        else
            $display("  >>> FAILURE: Data was corrupted");

        // ============================================================
        // SIMULATION COMPLETION
        // ============================================================
        #20;
        $display("[%0t] Memory unit test completed.", $time);
        $finish;
    end
endmodule