`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 12:42:22
// Design Name: 
// Module Name: synchronizer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module synchronizer #(
    parameter WIDTH = 3
) (
    input                   clk,
    input                   rst_n,
    input      [WIDTH:0]    d_in,
    output reg [WIDTH:0]    d_out
);
 
    reg [WIDTH:0] q1;
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1    <= 0;
            d_out <= 0;
        end
        else begin
            q1    <= d_in;
            d_out <= q1;
        end
    end
 
endmodule
