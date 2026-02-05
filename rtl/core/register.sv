// File: rtl/core/register.sv
// Brief: 32-entry, 64-bit register file with asynchronous read and synchronous write.
// x0 is hardwired to 0 (zero register). Includes register dump task for debugging.

module register (
    input  logic        clk,                     // system clock (for synchronous writes)
    input  logic        rst,                     // synchronous reset (clears all registers)
    input  logic [4:0]  A1,                      // read address 1 (rs1 - source register 1)
    input  logic [4:0]  A2,                      // read address 2 (rs2 - source register 2)
    input  logic [4:0]  A3,                      // write address (rd - destination register)
    input  logic [63:0] WD3,                     // write data (result to commit to register)
    input  logic        WE3,                     // write enable flag (1=commit write, 0=no write)
    output logic [63:0] RD1,                     // read data output 1 (value of rs1)
    output logic [63:0] RD2                      // read data output 2 (value of rs2)
);

    // ============================================================
    // REGISTER FILE STORAGE
    // ============================================================
    // 32 registers of 64 bits each (x1 to x31)
    // x0 is NOT stored (hardwired to 0 in read logic below)
    logic [63:0] rf [0:31];

    // ============================================================
    // SYNCHRONOUS WRITE (on negative clock edge)
    // ============================================================
    // Updates registers on the negative clock edge of the clock cycle
    // Writes only to x1-x31 (x0 is skipped due to the check: A3 != 5'b0)
    // All registers reset to 0 when rst signal is asserted
    
    always_ff @(negedge clk) begin
        if (rst) begin
            // Reset phase: clear all registers except x0 (which doesn't exist in storage)
            for (int i = 1; i < 32; i++) begin
                rf[i] <= 64'b0;                 // synchronous reset of all registers
            end
        end else if (WE3 && (A3 != 5'b0)) begin
            // Write phase: update register A3 with WD3 if WE3=1 and A3≠0
            // Skip write to x0 (zero register) by checking A3 != 5'b0
            rf[A3] <= WD3;
        end
    end
    
    // ============================================================
    // ASYNCHRONOUS READ (combinational)
    // ============================================================
    // Provides immediate read access to register values
    // Returns 0 for x0 reads, regardless of rf[0] value
    
    assign RD1 = (A1 == 5'b0) ? 64'b0 : rf[A1]; // read rs1: return 0 if x0, else rf[A1]
    assign RD2 = (A2 == 5'b0) ? 64'b0 : rf[A2]; // read rs2: return 0 if x0, else rf[A2]

    // ============================================================
    // DEBUG TASK: REGISTER FILE DUMP
    // ============================================================
    // Displays all 32 register values with their RISC-V ABI names for debugging
    
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