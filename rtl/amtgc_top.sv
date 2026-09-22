`timescale 1ns/1ps

module amtgc_top #(
    parameter int A_GREEN_TIME = 6,
    parameter int B_GREEN_TIME = 5,
    parameter int YELLOW_TIME  = 2,
    parameter int RED_TIME     = 2,
    parameter int PED_TIME     = 3,
    parameter int MIN_GREEN_TIME = 4,
    parameter int MAX_GREEN_TIME = 10,
    parameter int DENSITY_STEP = 1,
    parameter int WAVE_DELAY = 3,
    parameter int COUNTER_WIDTH = 8
) (
    input logic clk,
    input logic reset,
    input logic emergency_override,
    input logic ped_request_a,
    input logic ped_request_b,
    input logic [2:0] traffic_density_a,
    input logic [2:0] traffic_density_b,
    output logic a_ns_red, a_ns_yellow, a_ns_green,
    output logic a_ew_red, a_ew_yellow, a_ew_green,
    output logic b_ns_red, b_ns_yellow, b_ns_green,
    output logic b_ew_red, b_ew_yellow, b_ew_green,
    output logic a_ped_active, b_ped_active,
    output logic grant_a, grant_b,
    output logic wave_active
);

    logic a_pending, b_pending;
    logic a_ped_done, b_ped_done;
    logic a_ns_start, b_ns_start;
    logic b_wave_hold;
    logic b_wave_trigger;
    logic ped_busy;

    ped_arbiter u_ped_arbiter (
        .clk(clk), .reset(reset),
        .request_a(ped_request_a), .request_b(ped_request_b),
        .service_done(a_ped_done | b_ped_done),
        .grant_a(grant_a), .grant_b(grant_b), .busy(ped_busy)
    );

    junction_controller #(
        .GREEN_TIME(A_GREEN_TIME), .YELLOW_TIME(YELLOW_TIME),
        .RED_TIME(RED_TIME), .PED_TIME(PED_TIME),
        .MIN_GREEN_TIME(MIN_GREEN_TIME), .MAX_GREEN_TIME(MAX_GREEN_TIME),
        .DENSITY_STEP(DENSITY_STEP), .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_junction_a (
        .clk(clk), .reset(reset), .emergency_override(emergency_override),
        .ped_request(grant_a),
        .traffic_density(traffic_density_a), .green_wave_hold(1'b0),
        .green_wave_trigger(1'b0),
        .ns_red(a_ns_red), .ns_yellow(a_ns_yellow), .ns_green(a_ns_green),
        .ew_red(a_ew_red), .ew_yellow(a_ew_yellow), .ew_green(a_ew_green),
        .ped_active(a_ped_active), .ped_done(a_ped_done), .ns_green_start(a_ns_start),
        .request_pending(a_pending), .state_code()
    );

    junction_controller #(
        .GREEN_TIME(B_GREEN_TIME), .YELLOW_TIME(YELLOW_TIME),
        .RED_TIME(RED_TIME), .PED_TIME(PED_TIME),
        .MIN_GREEN_TIME(MIN_GREEN_TIME), .MAX_GREEN_TIME(MAX_GREEN_TIME),
        .DENSITY_STEP(DENSITY_STEP), .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_junction_b (
        .clk(clk), .reset(reset), .emergency_override(emergency_override),
        .ped_request(grant_b),
        .traffic_density(traffic_density_b), .green_wave_hold(b_wave_hold),
        .green_wave_trigger(b_wave_trigger),
        .ns_red(b_ns_red), .ns_yellow(b_ns_yellow), .ns_green(b_ns_green),
        .ew_red(b_ew_red), .ew_yellow(b_ew_yellow), .ew_green(b_ew_green),
        .ped_active(b_ped_active), .ped_done(b_ped_done), .ns_green_start(b_ns_start),
        .request_pending(b_pending), .state_code()
    );

    green_wave_controller #(
        .WAVE_DELAY(WAVE_DELAY), .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_green_wave (
        .clk(clk), .reset(reset),
        .a_ns_green_start(a_ns_start), .b_ns_green_start(b_ns_start),
        .b_wave_hold(b_wave_hold), .b_wave_trigger(b_wave_trigger), .wave_active(wave_active), .wave_count()
    );
endmodule
