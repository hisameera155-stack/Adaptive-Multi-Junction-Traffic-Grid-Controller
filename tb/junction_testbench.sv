`timescale 1ns/1ps
module junction_testbench;
    logic clk=0, reset=1, emergency_override=0, ped_request=0, green_wave_hold=0, green_wave_trigger=0;
    logic [2:0] traffic_density=0;
    logic ns_red,ns_yellow,ns_green,ew_red,ew_yellow,ew_green,ped_active,ns_green_start,request_pending,ped_done;
    logic [3:0] state_code;

    always #5 clk=~clk;

    junction_controller #(
        .GREEN_TIME(4), .YELLOW_TIME(2), .RED_TIME(2), .PED_TIME(3),
        .MIN_GREEN_TIME(4), .MAX_GREEN_TIME(8), .DENSITY_STEP(1), .COUNTER_WIDTH(8)
    ) dut (
        .clk(clk),.reset(reset),.emergency_override(emergency_override),.ped_request(ped_request),
        .traffic_density(traffic_density),.green_wave_hold(green_wave_hold),.green_wave_trigger(green_wave_trigger),
        .ns_red(ns_red),.ns_yellow(ns_yellow),.ns_green(ns_green),
        .ew_red(ew_red),.ew_yellow(ew_yellow),.ew_green(ew_green),
        .ped_active(ped_active),.ped_done(ped_done),.ns_green_start(ns_green_start),
        .request_pending(request_pending),.state_code(state_code)
    );

    initial begin
        $dumpfile("junction.vcd"); $dumpvars(0,junction_testbench);
        repeat(2) @(posedge clk); reset<=0;
        repeat(30) @(posedge clk);
        // request during yellow window
        ped_request<=1;
        @(posedge clk); ped_request<=0;
        repeat(20) @(posedge clk);
        // emergency
        emergency_override<=1;
        repeat(2) @(posedge clk);
        if (!(ns_red && ew_red && !ns_green && !ew_green)) $fatal(1,"FAIL: emergency did not force all-red");
        emergency_override<=0;
        repeat(12) @(posedge clk);
        $display("JUNCTION TESTBENCH PASS");
        $finish;
    end

    // Safety assertion: conflicting greens are never allowed.
    always @(posedge clk) begin
        assert (!(ns_green && ew_green)) else $fatal(1,"FAIL: conflicting green lights");
    end
endmodule
