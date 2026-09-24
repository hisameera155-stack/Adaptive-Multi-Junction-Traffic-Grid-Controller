`timescale 1ns/1ps
module amtgc_top_tb;
    logic clk=0, reset=1, emergency_override=0;
    logic ped_request_a=0, ped_request_b=0;
    logic [2:0] traffic_density_a=0, traffic_density_b=0;
    logic a_ns_red,a_ns_yellow,a_ns_green,a_ew_red,a_ew_yellow,a_ew_green;
    logic b_ns_red,b_ns_yellow,b_ns_green,b_ew_red,b_ew_yellow,b_ew_green;
    logic a_ped_active,b_ped_active,grant_a,grant_b,wave_active;
    integer fair_a=0, fair_b=0;

    always #5 clk=~clk;

    amtgc_top #(
        .A_GREEN_TIME(5),.B_GREEN_TIME(5),.YELLOW_TIME(2),.RED_TIME(2),.PED_TIME(3),
        .MIN_GREEN_TIME(3),.MAX_GREEN_TIME(7),.DENSITY_STEP(1),.WAVE_DELAY(3),.COUNTER_WIDTH(8)
    ) dut (
        .clk(clk),.reset(reset),.emergency_override(emergency_override),
        .ped_request_a(ped_request_a),.ped_request_b(ped_request_b),
        .traffic_density_a(traffic_density_a),.traffic_density_b(traffic_density_b),
        .a_ns_red(a_ns_red),.a_ns_yellow(a_ns_yellow),.a_ns_green(a_ns_green),
        .a_ew_red(a_ew_red),.a_ew_yellow(a_ew_yellow),.a_ew_green(a_ew_green),
        .b_ns_red(b_ns_red),.b_ns_yellow(b_ns_yellow),.b_ns_green(b_ns_green),
        .b_ew_red(b_ew_red),.b_ew_yellow(b_ew_yellow),.b_ew_green(b_ew_green),
        .a_ped_active(a_ped_active),.b_ped_active(b_ped_active),
        .grant_a(grant_a),.grant_b(grant_b),.wave_active(wave_active)
    );

    always @(posedge clk) begin
        assert (!(a_ns_green && a_ew_green)) else $fatal(1,"A conflict");
        assert (!(b_ns_green && b_ew_green)) else $fatal(1,"B conflict");
        if (grant_a) fair_a = fair_a + 1;
        if (grant_b) fair_b = fair_b + 1;
    end

    integer i;
    initial begin
        $dumpfile("amtgc.vcd"); $dumpvars(0,amtgc_top_tb);
        repeat(2) @(posedge clk); reset<=0;
        traffic_density_a<=3'd7; traffic_density_b<=3'd7;
        repeat(100) @(posedge clk);

        // Repeated simultaneous requests; allow each service to complete.
        for (i=0;i<110;i=i+1) begin
            @(posedge clk); ped_request_a<=1; ped_request_b<=1;
            @(posedge clk); ped_request_a<=0; ped_request_b<=0;
            repeat(6) @(posedge clk);
        end
        if (fair_a == 0 || fair_b == 0) $fatal(1,"FAIL: arbiter starved a side");

        // Emergency during operation.
        emergency_override<=1;
        repeat(2) @(posedge clk);
        if (!(a_ns_red && a_ew_red && b_ns_red && b_ew_red)) $fatal(1,"FAIL: emergency safety");
        emergency_override<=0;
        repeat(20) @(posedge clk);

        // Reset mid-simulation.
        reset<=1; @(posedge clk); reset<=0;
        repeat(10) @(posedge clk);
        $display("FAIR GRANTS: A=%0d B=%0d",fair_a,fair_b);
        $display("AMTGC INTEGRATION TESTBENCH PASS");
        $finish;
    end
endmodule
