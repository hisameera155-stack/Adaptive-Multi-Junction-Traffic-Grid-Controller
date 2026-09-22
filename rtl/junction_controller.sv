`timescale 1ns/1ps

module junction_controller #(
    parameter int GREEN_TIME     = 8,
    parameter int YELLOW_TIME    = 3,
    parameter int RED_TIME       = 2,
    parameter int PED_TIME       = 4,
    parameter int MIN_GREEN_TIME = GREEN_TIME,
    parameter int MAX_GREEN_TIME = GREEN_TIME + 8,
    parameter int DENSITY_STEP   = 2,
    parameter int COUNTER_WIDTH  = 8
) (
    input  logic                     clk,
    input  logic                     reset,
    input  logic                     emergency_override,
    input  logic                     ped_request,
    input  logic [2:0]               traffic_density,
    input  logic                     green_wave_hold,
    input  logic                     green_wave_trigger,
    output logic                     ns_red,
    output logic                     ns_yellow,
    output logic                     ns_green,
    output logic                     ew_red,
    output logic                     ew_yellow,
    output logic                     ew_green,
    output logic                     ped_active,
    output logic                     ped_done,
    output logic                     ns_green_start,
    output logic                     request_pending,
    output logic [3:0]               state_code
);

    typedef enum logic [3:0] {
        S_NS_GREEN  = 4'd0,
        S_NS_YELLOW = 4'd1,
        S_ALL_RED_1 = 4'd2,
        S_EW_GREEN  = 4'd3,
        S_EW_YELLOW = 4'd4,
        S_ALL_RED_2 = 4'd5,
        S_PED       = 4'd6,
        S_EMERGENCY = 4'd7
    } state_t;

    localparam int SAFE_RED_TIME = (RED_TIME < 1) ? 1 : RED_TIME;
    localparam int MAX_PHASE_TIME =
        (MAX_GREEN_TIME > PED_TIME) ?
        ((MAX_GREEN_TIME > YELLOW_TIME) ?
        ((MAX_GREEN_TIME > SAFE_RED_TIME) ? MAX_GREEN_TIME : SAFE_RED_TIME) :
        ((YELLOW_TIME > SAFE_RED_TIME) ? YELLOW_TIME : SAFE_RED_TIME)) :
        ((PED_TIME > YELLOW_TIME) ?
        ((PED_TIME > SAFE_RED_TIME) ? PED_TIME : SAFE_RED_TIME) :
        ((YELLOW_TIME > SAFE_RED_TIME) ? YELLOW_TIME : SAFE_RED_TIME));

    state_t state, next_state;
    logic ped_pending;
    logic wave_pending;
    logic [COUNTER_WIDTH-1:0] phase_target;
    logic [COUNTER_WIDTH-1:0] dynamic_green_time;
    logic timer_start;
    logic phase_start_pending;
    logic timer_done;
    logic timer_busy;
    logic [COUNTER_WIDTH-1:0] timer_count;
    logic [2:0] sampled_density;

    function automatic [COUNTER_WIDTH-1:0] clamp_green(input logic [2:0] density);
        int unsigned raw;
        begin
            raw = MIN_GREEN_TIME + (density * DENSITY_STEP);
            if (raw < MIN_GREEN_TIME)
                raw = MIN_GREEN_TIME;
            if (raw > MAX_GREEN_TIME)
                raw = MAX_GREEN_TIME;
            clamp_green = raw[COUNTER_WIDTH-1:0];
        end
    endfunction

    assign state_code = state;
    assign request_pending = ped_pending;

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) phase_timer (
        .clk(clk),
        .reset(reset),
        .start(timer_start),
        .count_target(phase_target),
        .done(timer_done),
        .busy(timer_busy),
        .count(timer_count)
    );

    always_comb begin
        dynamic_green_time = clamp_green(sampled_density);
        case (state)
            S_NS_GREEN, S_EW_GREEN: phase_target = dynamic_green_time;
            S_NS_YELLOW, S_EW_YELLOW: phase_target = YELLOW_TIME;
            S_ALL_RED_1, S_ALL_RED_2: phase_target = SAFE_RED_TIME;
            S_PED: phase_target = PED_TIME;
            default: phase_target = SAFE_RED_TIME;
        endcase
    end

    // The timer is started once on entry to each timed phase.
    always_comb begin
        timer_start = phase_start_pending && !emergency_override;
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state          <= S_ALL_RED_1;
            ped_pending    <= 1'b0;
            wave_pending   <= 1'b0;
            sampled_density <= '0;
            ns_green_start <= 1'b0;
            ped_done <= 1'b0;
            phase_start_pending <= 1'b1;
        end else if (emergency_override) begin
            state          <= S_EMERGENCY;
            wave_pending  <= 1'b0;
            ns_green_start <= 1'b0;
            ped_done <= 1'b0;
            phase_start_pending <= 1'b0;
        end else begin
            state          <= next_state;
            phase_start_pending <= (next_state != state);
            ns_green_start <= (next_state == S_NS_GREEN) && (state != S_NS_GREEN);
            ped_done <= (state == S_PED) && (next_state != S_PED);

            if (green_wave_trigger)
                wave_pending <= 1'b1;
            if (next_state == S_NS_GREEN)
                wave_pending <= 1'b0;

            if (ped_request && (state != S_PED))
                ped_pending <= 1'b1;
            if ((next_state == S_PED) && (state != S_PED))
                ped_pending <= 1'b0;

            if ((next_state == S_NS_GREEN) || (next_state == S_EW_GREEN))
                sampled_density <= traffic_density;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            S_NS_GREEN: begin
                if (timer_done)
                    next_state = S_NS_YELLOW;
            end
            S_NS_YELLOW: begin
                if (timer_done)
                    next_state = S_ALL_RED_1;
            end
            S_ALL_RED_1: begin
                if (timer_done) begin
                    if (ped_pending)
                        next_state = S_PED;
                    else if (wave_pending || green_wave_hold)
                        next_state = S_NS_GREEN;
                    else
                        next_state = S_EW_GREEN;
                end
            end
            S_EW_GREEN: begin
                if (timer_done)
                    next_state = S_EW_YELLOW;
            end
            S_EW_YELLOW: begin
                if (timer_done)
                    next_state = S_ALL_RED_2;
            end
            S_ALL_RED_2: begin
                if (timer_done) begin
                    if (ped_pending)
                        next_state = S_PED;
                    else
                        next_state = S_NS_GREEN;
                end
            end
            S_PED: begin
                if (timer_done)
                    next_state = S_ALL_RED_2;
            end
            S_EMERGENCY: begin
                next_state = S_ALL_RED_1;
            end
            default: begin
                next_state = S_ALL_RED_1;
            end
        endcase
    end

    always_comb begin
        ns_red     = 1'b1;
        ns_yellow  = 1'b0;
        ns_green   = 1'b0;
        ew_red     = 1'b1;
        ew_yellow  = 1'b0;
        ew_green   = 1'b0;
        ped_active = 1'b0;

        case (state)
            S_NS_GREEN: begin
                ns_red   = 1'b0;
                ns_green = 1'b1;
            end
            S_NS_YELLOW: begin
                ns_red    = 1'b0;
                ns_yellow = 1'b1;
            end
            S_ALL_RED_1: begin end
            S_EW_GREEN: begin
                ew_red   = 1'b0;
                ew_green = 1'b1;
            end
            S_EW_YELLOW: begin
                ew_red    = 1'b0;
                ew_yellow = 1'b1;
            end
            S_ALL_RED_2: begin end
            S_PED: begin
                ped_active = 1'b1;
            end
            S_EMERGENCY: begin end
            default: begin end
        endcase
    end
endmodule
