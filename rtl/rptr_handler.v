`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 12:44:58
// Design Name: 
// Module Name: rptr_handler
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
// Read Pointer Handler
// Generates binary + Gray read pointers and the EMPTY flag,
// using the write pointer (already synchronized into the
// read clock domain).
// ==========================================================
module rptr_handler #(
    parameter PTR_WIDTH = 3
) (
    input                      rclk,
    input                      rrst_n,
    input                      r_en,
    input      [PTR_WIDTH:0]   g_wptr_sync,
    output reg [PTR_WIDTH:0]   b_rptr,
    output reg [PTR_WIDTH:0]   g_rptr,
    output reg                 empty
);

    wire [PTR_WIDTH:0] b_rptr_next;
    wire [PTR_WIDTH:0] g_rptr_next;
    wire                rempty;

    assign b_rptr_next = b_rptr + (r_en & !empty);
    assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;

    // empty occurs when the next gray read pointer catches up
    // to the synchronized gray write pointer
    
    assign rempty = (g_wptr_sync == g_rptr_next);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            b_rptr <= 0;
            g_rptr <= 0;
        end
        else begin
            b_rptr <= b_rptr_next;
            g_rptr <= g_rptr_next;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) empty <= 1'b1;
        else         empty <= rempty;
    end

endmodule


