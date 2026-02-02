module data (
    input  logic        clk,
    input  logic        WE,      
    input  logic [63:0] A,       
    input  logic [63:0] WD,      
    output logic [63:0] RD       
);

    logic [63:0] ram [1023:0]; 

    // Synchronous Read and Write Logic
    // This ensures data is stable for the MW_pipeline register
    always_ff @(posedge clk) begin
        if (WE) begin
            ram[A[12:3]] <= WD;
        end
        RD <= ram[A[12:3]]; // Synchronous Read
    end

    task dump_mem;
        integer k; 
        begin
            $display("\n========================= DATA MEMORY DUMP =========================");
            $display(" Address    | Value (Hex)            | Decimal");
            $display("--------------------------------------------------------------------");
            for (k = 0; k < 32; k = k + 1) begin
                $display(" 0x%08h | %h | %d", k*8, ram[k], ram[k]);
            end
            $display("====================================================================\n");
        end
    endtask
    
endmodule
