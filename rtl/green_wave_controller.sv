`timescale 1ns/1ps

module green_wave_controller #(
    parameter int WAVE_DELAY = 3,
    parameter int COUNTER_WIDTH = 8
) (
    input  logic clk,
    input  logic reset,
    input  logic a_ns_green_start,
    input  logic b_ns_green_start,
    output logic b_wave_hold,
    output logic b_wave_trigger,
    output logic wave_active,
    output logic [COUNTER_WIDTH-1:0] wave_count
);
    logic [COUNTER_WIDTH-1:0] target;
    logic counting;

    assign target = WAVE_DELAY;

    always_ff @(posedge clk) begin
        if (reset) begin
            wave_count <= '0;
            counting   <= 1'b0;
            b_wave_hold <= 1'b0;
            b_wave_trigger <= 1'b0;
        end else begin
            b_wave_trigger <= 1'b0;
            if (a_ns_green_start) begin
                wave_count  <= '0;
                counting    <= 1'b1;
                b_wave_hold <= (WAVE_DELAY != 0);
            end else if (counting) begin
                if (WAVE_DELAY == 0 || wave_count >= target - 1'b1) begin
                    counting    <= 1'b0;
                    b_wave_hold <= 1'b0;
                    b_wave_trigger <= 1'b1;
                end else begin
                    wave_count <= wave_count + 1'b1;
                end
            end
            if (b_ns_green_start)
                b_wave_hold <= 1'b0;
        end
    end

    assign wave_active = counting;
endmodule
