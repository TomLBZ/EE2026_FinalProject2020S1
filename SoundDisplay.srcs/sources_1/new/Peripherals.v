`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/13/2020 07:10:27 PM
// Design Name: FGPA Project for EE2026
// Module Name: Peripherals
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module provides peripheral utilities needed for the project that are unrelated to sound or display.
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module TripleChannelClock(input CLOCK, input [2:0] RST, input [4:0] SlowBit, output FCLK, output MCLK, output SCLK);
    reg [3:0] cf = 4'b0;//accumulator for the 6.25MHz clock, highest bit toggles
    reg [11:0] cm = 12'h0;//accumulator for the 20kHz clock, accumulates
    reg [31:0] cs = 32'h0;//accumulator for any other slow clock to be used later, toggles
    reg mid = 0;
    always @ (posedge CLOCK) begin
        if (RST > 0) begin
            if (RST[0]) cs <= 0;
            if (RST[1]) begin cm <= 0; mid <= 0; end
            if (RST[2]) cf <= 0;
        end else begin 
            cf <= cf + 1;
            cs <= cs + 1;
            if (cm < 2499) cm <= cm + 1;
            else if (cm == 2499) begin mid <= ~mid; cm <= 0; end
        end
    end
    assign FCLK = cf[3];//6.25MHz (0.005us ahead of main clk)
    assign SCLK = cs[SlowBit];//(0.005us ahead of main clk)
    assign MCLK = mid;//20kHz (0.005us ahead of main clk)
endmodule
module dff(input CLK, D, output reg Q=0);
    always @ (posedge CLK) begin
        Q<=D;
    end
endmodule
module pulser(input D,input CLK, output out);
    wire Q1;
    wire Q2;
    dff dff1(CLK,D,Q1);
    dff dff2(CLK,Q1,Q2);
    assign out=Q1&~Q2;
endmodule
module btnDebouncer(input CLOCK, input [4:0] btn, output [4:0] BTN_PULSE);
    pulser p0(btn[0],CLOCK,BTN_PULSE[0]);
    pulser p1(btn[1],CLOCK,BTN_PULSE[1]);
    pulser p2(btn[2],CLOCK,BTN_PULSE[2]);
    pulser p3(btn[3],CLOCK,BTN_PULSE[3]);
    pulser p4(btn[4],CLOCK,BTN_PULSE[4]);
endmodule
module M21(input D1, input D2, input S, output Q);
    assign Q = S ? D1 : D2;
endmodule
module B12_MUX(input [11:0] D1, input [11:0] D2, input S, output [11:0] Q);
    M21 M0(D1[0],D2[0],S,Q[0]);
    M21 M1(D1[1],D2[1],S,Q[1]);
    M21 M2(D1[2],D2[2],S,Q[2]);
    M21 M3(D1[3],D2[3],S,Q[3]);
    M21 M4(D1[4],D2[4],S,Q[4]);
    M21 M5(D1[5],D2[5],S,Q[5]);
    M21 M6(D1[6],D2[6],S,Q[6]);
    M21 M7(D1[7],D2[7],S,Q[7]);
    M21 M8(D1[8],D2[8],S,Q[8]);
    M21 M9(D1[9],D2[9],S,Q[9]);
    M21 M10(D1[10],D2[10],S,Q[10]);
    M21 M11(D1[11],D2[11],S,Q[11]);
endmodule
module Peripherals(
    input CLOCK, [2:0] clkReset, [4:0] slowBit, [4:0] btns,
    output [3:0] Clock,//100M, 6.25M, 20k, _flexible_
    output [4:0] debouncedBtns
    );
    TripleChannelClock tcc(CLOCK,clkReset,slowBit,Clock[2],Clock[1],Clock[0]);
    btnDebouncer bd(Clock[2],btns,debouncedBtns);
    assign Clock[3] = CLOCK;
endmodule
