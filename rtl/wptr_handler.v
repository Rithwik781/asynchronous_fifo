`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 12:43:41
// Design Name: 
// Module Name: wptr_handler
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
// Write Pointer Handler
// Generates binary + Gray write pointers and the FULL flag,
// using the read pointer (already synchronized into the
// write clock domain).
// ==========================================================
module wptr_handler #(
    parameter PTR_WIDTH = 3
) (
    input                      wclk,
    input                      wrst_n,
    input                      w_en,
    input      [PTR_WIDTH:0]   g_rptr_sync,
    output reg [PTR_WIDTH:0]   b_wptr,
    output reg [PTR_WIDTH:0]   g_wptr,
    output reg                 full
);

    wire [PTR_WIDTH:0] b_wptr_next;
    wire [PTR_WIDTH:0] g_wptr_next;
    wire                wfull;

    assign b_wptr_next = b_wptr + (w_en & !full);
    assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;

    // full occurs when the next gray write pointer equals the
    // synchronized gray read pointer with the top two MSBs inverted
    
    
    assign wfull = (g_wptr_next == {~g_rptr_sync[PTR_WIDTH:PTR_WIDTH-1],
                                      g_rptr_sync[PTR_WIDTH-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            b_wptr <= 0;
            g_wptr <= 0;
        end
        else begin
            b_wptr <= b_wptr_next;
            g_wptr <= g_wptr_next;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) full <= 1'b0;
        else         full <= wfull;
    end

endmodule
