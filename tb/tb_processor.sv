// File: tb/tb_processor.sv
// Brief: Top-level testbench for RV64I-Zba pipelined processor core.
// Instantiates the core, generates clock/reset, loads test program,
// monitors register/memory state, and detects test success/failure conditions.

`timescale 1ns/1ps

module tb_processor();
    // ============================================================
    // CLOCK AND RESET SIGNALS
    // ============================================================
    logic clk;                                  // system clock (toggled every 5ns = 100MHz)
    logic rst;                                  // synchronous reset signal

    // ============================================================
    // DUT INSTANTIATION (Core)
    // ============================================================
    // Instantiate the top-level processor core with clock and reset
    core dut (
        .clk(clk),                              // connect system clock
        .rst(rst)                               // connect reset signal
    );

    // ============================================================
    // CLOCK GENERATION
    // ============================================================
    // Generate 100MHz clock: toggle every 5ns (10ns period)
    always #5 clk = ~clk;

    // ============================================================
    // TESTBENCH MAIN SEQUENCE
    // ============================================================
    initial begin
        // ============================================================
        // 1. VCD WAVEFORM DUMP SETUP
        // ============================================================
        // Capture all signals for waveform analysis (debug/viewing)
        $dumpfile("core_sim.vcd");              // output waveform file
        $dumpvars(0, tb_processor);             // record all signals in testbench

        // ============================================================
        // 2. CLOCK AND RESET INITIALIZATION
        // ============================================================
        // Initialize clock to 0, hold reset inactive
        clk = 0;                                // start clock at 0
        rst = 0;                                // reset inactive
        #1 rst = 1;                             // pulse reset to 1 after 1ns for logic settling

        // ============================================================
        // 3. TEST PROGRAM LOADING
        // ============================================================
        // Load compiled RISC-V binary from hex file into instruction ROM
        $display("Status: Loading software...");
        $readmemh("sw/build/test.hex", dut.IF_STAGE.imem.rom); // load instructions into ROM

        // ============================================================
        // 4. DATA MEMORY INITIALIZATION
        // ============================================================
        // Clear all data memory locations, then initialize test data
        for (int i = 0; i < 1024; i++) begin
            dut.MEM_STAGE.data_mem.ram[i] = 64'b0; // zero-initialize all RAM locations
        end
        
        // Optionally pre-load test data into memory
        dut.MEM_STAGE.data_mem.ram[0] = 64'hDEADBEEFCAFEBABE; // test pattern in ram[0]
        
        // ============================================================
        // 5. RESET PULSE HOLD
        // ============================================================
        // Hold reset for 10 clock cycles to ensure all pipeline stages clear
        repeat (10) @(posedge clk);             // wait 10 clock edges
        
        @(negedge clk);                         // wait for negative edge
        rst = 0;                                // release reset (processor begins execution)
        $display("Status: Reset released.");
        
        // ============================================================
        // 6. PARALLEL MONITORS & TIMEOUT
        // ============================================================
        // Run two processes in parallel: timeout and result monitoring
        fork
            // TIMEOUT PROCESS: Stop simulation after 10000ns
            begin : timeout
                #10000;                         // wait 10000ns (100 clock cycles @ 100MHz)
                $display("Status: Simulation duration reached. Finalizing...");
                
                // Dump final register and memory state
                dut.MEM_STAGE.data_mem.dump_mem(); // display memory contents
                dut.ID_STAGE.rf.dump_regs(dut.PC_E); // display register file
                $finish;                        // end simulation
            end
            
            // MONITOR PROCESS: Check for test completion conditions
            begin : monitor_results
                forever begin
                    @(negedge clk);             // sample on every negative clock edge
                    
                    // ========== ASSERTION 1: PC Validity Check ==========
                    // Detect if PC becomes unknown (X) during execution
                    // This indicates a hardware malfunction
                    if ($isunknown(dut.PC_F) && !rst) begin
                        $display("ASSERTION FAILED: PC went to X at time %0t", $time);
                        $finish;                // stop simulation on PC corruption
                    end

                    // ========== ASSERTION 2: Zero Register Write Protection ==========
                    // Detect illegal writes to x0 (should always be 0)
                    // Only flag if non-zero value is written to x0
                    if (dut.ID_STAGE.rf.WE3 && (dut.ID_STAGE.rf.A3 == 5'b0) && !rst) begin
                        // Print warning only if attempting to write non-zero value
                        if (dut.ID_STAGE.rf.WD3 !== 64'b0) begin
                            $display("WARNING: Attempted write of %h to x0 at time %0t", dut.ID_STAGE.rf.WD3, $time);
                        end
                    end

                    // ========== SUCCESS CONDITION: Checksum Match ==========
                    // Test succeeds if register x31 contains checksum 0x7FF
                    // This is written by test program upon successful completion
                    if (dut.ID_STAGE.rf.rf[31] === 64'h7FF) begin
                        $display("SUCCESS: Checksum 0x7FF detected in x31!");
                        #100;                   // wait 100ns before dumping
                        dut.MEM_STAGE.data_mem.dump_mem(); // show final memory state
                        dut.ID_STAGE.rf.dump_regs(dut.PC_E); // show final registers
                        $finish;                // end simulation (test passed)
                    end
                end
            end
        join
    end
endmodule