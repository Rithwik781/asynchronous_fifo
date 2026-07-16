
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 12:49:27
// Design Name: 
// Module Name: tb_afifo
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
`timescale 1ns / 1ps
module tb_afifo;
    parameter DEPTH = 8, DW = 8;

    reg wclk = 0, rclk = 0, wrst_n = 0, rrst_n = 0;
    reg w_en = 0, r_en = 0;
    reg [DW-1:0] data_in = 0;
    wire [DW-1:0] data_out;
    wire full, empty;

    integer errors = 0;
    integer i;
    reg [DW-1:0] expected [0:31];
    integer wr_idx = 0, rd_idx = 0;

    asynchronous_fifo #(DEPTH, DW) dut (
        .wclk(wclk), .wrst_n(wrst_n),
        .rclk(rclk), .rrst_n(rrst_n),
        .w_en(w_en), .r_en(r_en),
        .data_in(data_in), .data_out(data_out),
        .full(full), .empty(empty)
    );

    always #5  wclk = ~wclk;   // 100MHz write clk
    always #7  rclk = ~rclk;   // ~71MHz read clk

    // drive one write, sampled cleanly 1ns after the write edge
    task do_write(input [DW-1:0] d);
        begin
            @(posedge wclk); #1;
            w_en = 1;
            data_in = d;
            @(posedge wclk); #1;
            w_en = 0;
        end
    endtask

    initial begin
        wrst_n = 0; rrst_n = 0;
        w_en = 0; r_en = 0;
        repeat (3) @(posedge wclk);
        wrst_n = 1;
        repeat (3) @(posedge rclk);
        rrst_n = 1;

        #1;
        if (empty !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: empty should be 1 after reset");
        end
        if (full !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL: full should be 0 after reset");
        end

        // Fill the FIFO completely (DEPTH writes), one clean write per call
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge wclk); #1;
            w_en = 1;
            data_in = i + 8'hA0;
            expected[wr_idx] = i + 8'hA0;
            wr_idx = wr_idx + 1;
            @(posedge wclk); #1;
            w_en = 0;
        end

        repeat (5) @(posedge wclk); #1;

        if (full !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: full should be 1 after writing DEPTH entries, got %b", full);
        end

        // try writing while full - should be blocked (no effect on memory)
        @(posedge wclk); #1;
        w_en = 1;
        data_in = 8'hFF;
        @(posedge wclk); #1;
        w_en = 0;

        // Drain the FIFO and check data + emptying behavior.
        // data_out is combinational (shows current head); sample it,
        // then pulse r_en for one clock to pop/advance the pointer.
        
        repeat (3) @(posedge rclk); #1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            if (data_out !== expected[rd_idx]) begin
                errors = errors + 1;
                $display("FAIL: read %0d expected %h got %h", i, expected[rd_idx], data_out);
            end
            rd_idx = rd_idx + 1;
            r_en = 1;
            @(posedge rclk); #1;
            r_en = 0;
        end

        repeat (5) @(posedge rclk); #1;

        if (empty !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: empty should be 1 after draining all entries, got %b", empty);
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

    initial begin
        #3000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
