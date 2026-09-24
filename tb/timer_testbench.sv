`timescale 1ns/1ps
module timer_testbench;
    logic clk = 0;
    logic reset = 1;
    logic start = 0;
    logic [3:0] target3 = 4'd3;
    logic [5:0] target7 = 6'd7;
    logic [7:0] target12 = 8'd12;
    logic done3, done7, done12;
    logic busy3, busy7, busy12;
    logic [3:0] count3;
    logic [5:0] count7;
    logic [7:0] count12;

    always #5 clk = ~clk;

    generic_timer #(.COUNTER_WIDTH(4)) t3 (.clk(clk),.reset(reset),.start(start),.count_target(target3),.done(done3),.busy(busy3),.count(count3));
    generic_timer #(.COUNTER_WIDTH(6)) t7 (.clk(clk),.reset(reset),.start(start),.count_target(target7),.done(done7),.busy(busy7),.count(count7));
    generic_timer #(.COUNTER_WIDTH(8)) t12 (.clk(clk),.reset(reset),.start(start),.count_target(target12),.done(done12),.busy(busy12),.count(count12));

    initial begin
        $dumpfile("timer.vcd");
        $dumpvars(0,timer_testbench);
        repeat (2) @(posedge clk);
        reset <= 0;
        @(posedge clk); start <= 1;
        @(posedge clk); start <= 0;
        wait(done3); $display("PASS: target 3 completed");
        wait(done7); $display("PASS: target 7 completed");
        wait(done12); $display("PASS: target 12 completed");

        // zero target
        target3 <= 0;
        @(posedge clk); start <= 1;
        @(posedge clk); start <= 0;
        if (!done3) $fatal(1,"FAIL: zero target did not complete immediately");
        $display("PASS: zero target");

        // reset while counting
        target3 <= 4'd8;
        @(posedge clk); start <= 1;
        @(posedge clk); start <= 0;
        repeat (2) @(posedge clk);
        reset <= 1;
        @(posedge clk);
        reset <= 0;
        if (busy3 || done3 || count3 != 0) $fatal(1,"FAIL: reset while counting");
        $display("PASS: reset while counting");
        $display("TIMER TESTBENCH PASS");
        $finish;
    end
endmodule
