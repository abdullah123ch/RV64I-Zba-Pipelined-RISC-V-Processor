// Implements 32 64-bit registers with x0 hardwired to 0

module register (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  A1,  // Read Address 1 (rs1)
    input  logic [4:0]  A2,  // Read Address 2 (rs2)
    input  logic [4:0]  A3,  // Write Address (rd)
    input  logic [63:0] WD3, // Write Data
    input  logic        WE3, // Write Enable
    output logic [63:0] RD1, // Read Data 1
    output logic [63:0] RD2  // Read Data 2
);

    // 32 registers of 64 bits each
    logic [63:0] rf [31:1]; // x0 is omitted as it's hardwired to 0

    // Synchronous Write Logic
    always_ff @(negedge clk) begin
        if (rst) begin
            // Synchronous reset: happens on the next clock after rst goes high
            for (int i = 1; i < 32; i++) begin
                rf[i] <= 64'b0;
            end
        end else if (WE3 && (A3 != 5'b0)) begin
            rf[A3] <= WD3;
        end
    end
    
    // Asynchronous Read Logic (with x0 check)
    assign RD1 = (A1 == 5'b0) ? 64'b0 : rf[A1];
    assign RD2 = (A2 == 5'b0) ? 64'b0 : rf[A2];

    task dump_regs;
        begin
            $display("\n======================= FINAL REGISTER FILE STATE =======================");
            $display(" Name     | Reg | Value (Hex)");
            $display("-------------------------------------------------------------------------");
            $display(" ZERO     | x00 | 0000000000000000 (Hardwired)");
            $display(" RA       | x01 | %h", rf[1]);
            $display(" SP       | x02 | %h", rf[2]);
            $display(" GP       | x03 | %h", rf[3]);
            $display(" TP       | x04 | %h", rf[4]);
            $display(" T0       | x05 | %h", rf[5]);
            $display(" T1       | x06 | %h", rf[6]);
            $display(" T2       | x07 | %h", rf[7]);
            $display(" S0/Fp    | x08 | %h", rf[8]);
            $display(" S1       | x09 | %h", rf[9]);
            $display(" A0       | x10 | %h", rf[10]);
            $display(" A1       | x11 | %h", rf[11]);
            $display(" A2       | x12 | %h", rf[12]);
            $display(" A3       | x13 | %h", rf[13]);
            $display(" A4       | x14 | %h", rf[14]);
            $display(" A5       | x15 | %h", rf[15]);
            $display(" A6       | x16 | %h", rf[16]);
            $display(" A7       | x17 | %h", rf[17]);
            $display(" S2       | x18 | %h", rf[18]);
            $display(" S3       | x19 | %h", rf[19]);
            $display(" S4       | x20 | %h", rf[20]);
            $display(" S5       | x21 | %h", rf[21]);
            $display(" S6       | x22 | %h", rf[22]);
            $display(" S7       | x23 | %h", rf[23]);
            $display(" S8       | x24 | %h", rf[24]);
            $display(" S9       | x25 | %h", rf[25]);
            $display(" S10      | x26 | %h", rf[26]);
            $display(" S11      | x27 | %h", rf[27]);
            $display(" T3       | x28 | %h", rf[28]);
            $display(" T4       | x29 | %h", rf[29]);
            $display(" T5       | x30 | %h", rf[30]);
            $display(" T6       | x31 | %h", rf[31]);
            $display("=========================================================================\n");
        end
    endtask

endmodule