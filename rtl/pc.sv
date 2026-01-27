// 64-bit Program Counter (Simple Pipelined Version)
module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic [63:0] PCNext, 
    output logic [63:0] PC      
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 64'b0; 
        end else begin
            PC <= PCNext;
        end
    end

endmodule