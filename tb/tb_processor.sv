`timescale 1ns/1ps

module tb_processor();
    // 1. Clock and Reset Generation
    logic clk;
    logic rst;

    core dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    // 2. Instruction Memory & Data Memory Initialization
    initial begin
        $dumpfile("core_sim.vcd");
        $dumpvars(0, tb_processor);

        clk = 0; 
        rst = 1;

        // Initialize Instruction Memory
        $display("Status: Loading software into instruction memory...");
        $readmemh("sw/test.hex", dut.IF_STAGE.imem.rom, 0, 1023);

        // --- FIX: Initialize Data Memory to zero to remove 'X' values ---
        for (int i = 0; i < 1024; i++) begin
            dut.MEM_STAGE.data_mem.ram[i] = 64'b0;
        end

        #25; 
        rst = 0;
        $display("Status: Reset released, processor starting...");

        fork
            // 6. Simulation Termination Condition (Timeout)
            begin : timeout
                #10000; 
                $display("Status: Simulation duration reached. Finalizing...");
                
                // 4. Register and Data Memory Monitoring (Final State)
                dut.ID_STAGE.rf.dump_regs(dut.PC_E); 
                dut.MEM_STAGE.data_mem.dump_mem(); 
                $finish;
            end
            
            begin : monitor_results
                forever begin
                    @(negedge clk);
                    
                    // A: Check for invalid PC (X-detection)
                    if ($isunknown(dut.PC_F) && !rst) begin
                        $display("ASSERTION FAILED: PC went to X at time %0t", $time);
                        $finish;
                    end

                    // --- FIX: Refined Write to x0 Assertion ---
                    // Only warn if WE3 is high, A3 is 0, AND it's not a reset or a known NOP/Bubble
                    if (dut.ID_STAGE.rf.WE3 && (dut.ID_STAGE.rf.A3 == 5'b0) && !rst) begin
                        // Only print if the data being written is NOT zero (true violation)
                        if (dut.ID_STAGE.rf.WD3 !== 64'b0) begin
                            $display("WARNING: Attempted write of %h to x0 at time %0t", dut.ID_STAGE.rf.WD3, $time);
                        end
                    end

                    // C: Success Marker Detection (Checksum 0x7FF)
                    if (dut.ID_STAGE.rf.rf[31] === 64'h7FF) begin
                        $display("SUCCESS: Checksum 0x7FF detected in x31!");
                        #100;
                        dut.ID_STAGE.rf.dump_regs(dut.PC_E);
                        dut.MEM_STAGE.data_mem.dump_mem();
                        $finish;
                    end
                end
            end
        join
    end
endmodule