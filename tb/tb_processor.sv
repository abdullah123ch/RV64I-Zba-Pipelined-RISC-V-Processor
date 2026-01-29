`timescale 1ns/1ps

module tb_processor();
    logic clk;
    logic rst;

    core dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("core_sim.vcd");
        $dumpvars(0, tb_processor);

        clk = 0; rst = 1;
        $readmemh("sw/test.hex", dut.IF_STAGE.imem.rom, 0, 1023);

        #25; rst = 0;
        $display("Status: Reset released, processor starting...");

        fork
            begin : timeout
                #5000; 
                $display("Error: Simulation timed out!");
                // Call the task inside the register module instance
                dut.ID_STAGE.rf.dump_regs(); 
                $finish;
            end
            
            begin : monitor_results
                forever begin
                    @(negedge clk);
                    // Checking for x6 (sh1add result)
                    // Note: accessing index 6 is fine because it's a constant
                    if (dut.ID_STAGE.rf.rf[6] === 64'h28) begin
                        $display("Success: Detected Zba sh1add result (0x28)!");
                        #100;
                        dut.ID_STAGE.rf.dump_regs(); // Call internal task
                        $finish;
                    end
                end
            end
        join
    end

    // Cycle Logging
    always @(posedge clk) begin
        if (!rst) begin
            $display("Time=%0t | PC_F=%h | Instr_D=%h | Result_W=%h", 
                     $time, dut.PC_F, dut.Instr_D, dut.Result_W);
        end
    end

endmodule