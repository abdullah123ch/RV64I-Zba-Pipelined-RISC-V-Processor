`timescale 1ns/1ps

module tb_processor();
    // Testbench signals
    logic clk;
    logic rst;

    // Instantiate the Top-Level Core
    core dut (
        .clk(clk),
        .rst(rst)
    );

    // 1. Clock Generation (100MHz -> 10ns period)
    always #5 clk = ~clk;

    task print_registers;
        begin
            $display("\n======================= FINAL REGISTER FILE STATE =======================");
            $display("Reg  | Value (Hex)" );
            $display("-------------------------------------------------------------------------");
            for (int i = 0; i < 32; i++) begin
                // Format: x00 | 0000000000000000
                $display("x%02d  | %h", i, dut.ID_STAGE.rf.regs[i]);
            end
            $display("=========================================================================\n");
        end
    endtask

    // 2. Main Test Logic
    initial begin
        // --- Setup Waveform Dumping ---
        $dumpfile("core_sim.vcd");
        $dumpvars(0, tb_processor);

        // --- Initialize Signals ---
        clk = 0;
        rst = 1;

        // --- Hierarchical Memory Loading ---
        // Path: dut (core) -> IF_STAGE (fetch) -> imem (instruction) -> rom (logic array)
        $display("Status: Loading software into instruction memory...");
        $readmemh("sw/test.hex", dut.IF_STAGE.imem.rom, 0, 1023);

        // --- Release Reset ---
        #25;
        rst = 0;
        $display("Status: Reset released, processor starting...");

        // --- Monitoring ---
        // Let's look for our Zba result (0x28) in the Writeback Result
        // and add a safety timeout.
        fork
            begin : timeout
                #5000; // 500 cycles safety limit
                $display("Error: Simulation timed out!");
                print_registers();
                $finish;
            end
            
            begin : monitor_results
                forever begin
                    @(negedge clk);
                    // Check if the Writeback stage is writing the Zba result to register
                    // Result_W is in your core.sv module
                    if (dut.ID_STAGE.rf.regs[6] === 64'h28) begin
                        $display("Success: Detected Zba sh1add result (0x28)!");
                        #100; 
                        print_registers();
                        $finish;
                    end
                end
            end
        join
    end

    // 3. Optional: Print Instruction Flow to Console
    always @(posedge clk) begin
        if (!rst) begin
            $display("Time=%0t | PC_F=%h | Instr_D=%h | Result_W=%h", 
                     $time, dut.PC_F, dut.Instr_D, dut.Result_W);
        end
    end

endmodule