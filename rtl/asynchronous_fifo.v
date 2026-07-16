`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 12:47:50
// Design Name: 
// Module Name: asynchronous_fifo
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
// Asynchronous FIFO -
// Connects synchronizers, pointer handlers, and memory.
// ==========================================================

module asynchronous_fifo #(
    parameter DEPTH      = 8,
    parameter DATA_WIDTH = 8
) (
    input                       wclk,
    input                       wrst_n,
    input                       rclk,
    input                       rrst_n,
    input                       w_en,
    input                       r_en,
    input      [DATA_WIDTH-1:0] data_in,
    output     [DATA_WIDTH-1:0] data_out,
    output                      full,
    output                      empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    wire [PTR_WIDTH:0] g_wptr_sync, g_rptr_sync;
    wire [PTR_WIDTH:0] b_wptr, b_rptr;
    wire [PTR_WIDTH:0] g_wptr, g_rptr;

    // synchronize write pointer into the read clock domain
    synchronizer #(PTR_WIDTH) sync_wptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .d_in  (g_wptr),
        .d_out (g_wptr_sync)
    );

    // synchronize read pointer into the write clock domain
    synchronizer #(PTR_WIDTH) sync_rptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .d_in  (g_rptr),
        .d_out (g_rptr_sync)
    );

    wptr_handler #(PTR_WIDTH) wptr_h (
        .wclk        (wclk),
        .wrst_n      (wrst_n),
        .w_en        (w_en),
        .g_rptr_sync (g_rptr_sync),
        .b_wptr      (b_wptr),
        .g_wptr      (g_wptr),
        .full        (full)
    );

    rptr_handler #(PTR_WIDTH) rptr_h (
        .rclk        (rclk),
        .rrst_n      (rrst_n),
        .r_en        (r_en),
        .g_wptr_sync (g_wptr_sync),
        .b_rptr      (b_rptr),
        .g_rptr      (g_rptr),
        .empty       (empty)
    );

    fifo_mem #(DEPTH, DATA_WIDTH, PTR_WIDTH) fifom (
        .wclk     (wclk),
        .w_en     (w_en),
        .b_wptr   (b_wptr),
        .b_rptr   (b_rptr),
        .data_in  (data_in),
        .full     (full),
        .data_out (data_out)
    );

endmodule


