`timescale 1ns/1ps

module generic_timer #(
    parameter int COUNTER_WIDTH = 8
) (
    input  logic                     clk,
    input  logic                     reset,
    input  logic                     start,
    input  logic [COUNTER_WIDTH-1:0] count_target,
    output logic                     done,
    output logic                     busy,
    output logic [COUNTER_WIDTH-1:0] count
);

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= '0;
            done  <= 1'b0;
            busy  <= 1'b0;
        end else if (start) begin
            if (count_target == '0) begin
                count <= '0;
                done  <= 1'b1;
                busy  <= 1'b0;
            end else begin
                count <= '0;
                done  <= 1'b0;
                busy  <= 1'b1;
            end
        end else if (busy) begin
            if (count == count_target - 1'b1) begin
                count <= count_target;
                done  <= 1'b1;
                busy  <= 1'b0;
            end else begin
                count <= count + 1'b1;
                done  <= 1'b0;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule
