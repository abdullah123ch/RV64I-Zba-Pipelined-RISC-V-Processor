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
                // Set this to a duration long enough for your C code to finish
                #10000; 
                $display("Status: Simulation duration reached. Dumping registers...");
                dut.ID_STAGE.rf.dump_regs(); 
                $finish;
            end
            
            // We removed the specific Success check to allow free-run testing
            begin : monitor_results
                forever begin
                    @(negedge clk);
                    // You can add generic failure checks here if needed, 
                    // like checking for X values in the PC.
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