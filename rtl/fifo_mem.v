`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 12:46:24
// Design Name: 
// Module Name: fifo_mem
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

// ==========================================================
// Dual-Port FIFO Memory
// Synchronous write, asynchronous (combinational) read.
// ==========================================================
module fifo_mem #(
    parameter DEPTH      = 8,
    parameter DATA_WIDTH = 8,
    parameter PTR_WIDTH  = 3
) (
    input                          wclk,
    input                          w_en,
    input      [PTR_WIDTH:0]       b_wptr,
    input      [PTR_WIDTH:0]       b_rptr,
    input      [DATA_WIDTH-1:0]    data_in,
    input                          full,
    output     [DATA_WIDTH-1:0]    data_out
);

    reg [DATA_WIDTH-1:0] fifo [0:DEPTH-1];

    always @(posedge wclk) begin
        if (w_en & !full) begin
            fifo[b_wptr[PTR_WIDTH-1:0]] <= data_in;
        end
    end

    // combinational read
    assign data_out = fifo[b_rptr[PTR_WIDTH-1:0]];

endmodule
