`timescale 1ns/1ps

module ped_arbiter (
    input  logic clk,
    input  logic reset,
    input  logic request_a,
    input  logic request_b,
    input  logic service_done,
    output logic grant_a,
    output logic grant_b,
    output logic busy
);
    logic pending_a, pending_b;
    logic owner; // 0=A, 1=B
    logic last_grant;

    always_ff @(posedge clk) begin
        if (reset) begin
            pending_a <= 1'b0;
            pending_b <= 1'b0;
            owner     <= 1'b0;
            last_grant <= 1'b1; // first simultaneous request -> A
        end else begin
            if (request_a) pending_a <= 1'b1;
            if (request_b) pending_b <= 1'b1;

            if (!busy) begin
                if (pending_a && pending_b) begin
                    owner      <= ~last_grant;
                    last_grant <= ~last_grant;
                end else if (pending_a) begin
                    owner      <= 1'b0;
                    last_grant <= 1'b0;
                end else if (pending_b) begin
                    owner      <= 1'b1;
                    last_grant <= 1'b1;
                end
            end else if (service_done) begin
                if (owner == 1'b0)
                    pending_a <= 1'b0;
                else
                    pending_b <= 1'b0;
            end
        end
    end

    always_comb begin
        grant_a = 1'b0;
        grant_b = 1'b0;
        busy = pending_a | pending_b;
        if (busy) begin
            if (owner == 1'b0)
                grant_a = 1'b1;
            else
                grant_b = 1'b1;
        end
    end
endmodule
