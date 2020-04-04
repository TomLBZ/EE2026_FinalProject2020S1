`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/13/2020 07:10:27 PM
// Design Name: FGPA Project for EE2026
// Module Name: TripleChannelClock,dff, pulser, btnDebouncer, M21,B12_MUX,swState,srLatch,Peripherals
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module provides peripheral utilities needed for the project that are unrelated to sound or display but might be useful for both.
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////

module QuadripleChannelClock(input CLOCK, input [2:0] RST, input [4:0] SlowBit, output FCLK, output MCLK, output SCLK, output CLK10HZ);
    reg [3:0] cf = 4'b0;//accumulator for the 6.25MHz clock, highest bit toggles
    reg [11:0] cm = 12'h0;//accumulator for the 20kHz clock, accumulates
    reg [31:0] cs = 32'h0;//accumulator for any other slow clock to be used later, toggles
    reg [22:0] c10 = 23'h0;//accumulator for 10kHz clk
    reg mid = 0;
    reg bad = 0;
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
            if (c10 < 4999999) c10 <= c10 + 1;
            else if (c10 == 4999999) begin bad <= ~bad; c10 <= 0; end
        end
    end
    assign FCLK = cf[3];//6.25MHz (0.005us ahead of main clk)
    assign SCLK = cs[SlowBit];//(0.005us ahead of main clk)
    assign MCLK = mid;//20kHz (0.005us ahead of main clk)
    assign CLK10HZ = bad;//10Hz (0.005us ahead of main clk)
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

module M21(input D1, input D2, input S, output Q);
    assign Q = S ? D1 : D2;
endmodule

module B16_MUX(input [15:0] D1, input [15:0] D2, input S, output [15:0] Q);
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
    M21 M12(D1[12],D2[12],S,Q[12]);
    M21 M13(D1[13],D2[13],S,Q[13]);
    M21 M14(D1[14],D2[14],S,Q[14]);
    M21 M15(D1[15],D2[15],S,Q[15]);
endmodule

module ButtonStates(input [4:0] btn, input CLK, output [4:0] IsButtonPressed, output [4:0] ButtonPressPulses, output [4:0] ButtonReleasePulses);
    wire [4:0] PressPulses;
    wire [4:0] ReleasePulses;
    reg [4:0] States;
    pulser p0(btn[0],CLK,PressPulses[0]);
    pulser p1(btn[1],CLK,PressPulses[1]);
    pulser p2(btn[2],CLK,PressPulses[2]);
    pulser p3(btn[3],CLK,PressPulses[3]);
    pulser p4(btn[4],CLK,PressPulses[4]);
    pulser p5(~btn[0],CLK,ReleasePulses[0]);
    pulser p6(~btn[1],CLK,ReleasePulses[1]);
    pulser p7(~btn[2],CLK,ReleasePulses[2]);
    pulser p8(~btn[3],CLK,ReleasePulses[3]);
    pulser p9(~btn[4],CLK,ReleasePulses[4]);
    always @ (posedge CLK) begin
        if (PressPulses[0]) States[0] = 1;
        if (PressPulses[1]) States[1] = 1;
        if (PressPulses[2]) States[2] = 1;
        if (PressPulses[3]) States[3] = 1;
        if (PressPulses[4]) States[4] = 1;
        if (ReleasePulses[0]) States[0] = 0;
        if (ReleasePulses[1]) States[1] = 0;
        if (ReleasePulses[2]) States[2] = 0;
        if (ReleasePulses[3]) States[3] = 0;
        if (ReleasePulses[4]) States[4] = 0;
    end
    assign IsButtonPressed = States;
    assign ButtonPressPulses = PressPulses;
    assign ButtonReleasePulses = ReleasePulses;
endmodule

module SwitchStates(input [15:0] sw, input CLK, output [15:0] IsSwitchOn, output [15:0] SwitchOnPulses, output [15:0] SwitchOffPulses);
    wire [15:0] OnPulses;
    wire [15:0] OffPulses;
    reg [15:0] States;
    pulser p0(sw[0],CLK,OnPulses[0]);
    pulser p1(sw[1],CLK,OnPulses[1]);
    pulser p2(sw[2],CLK,OnPulses[2]);
    pulser p3(sw[3],CLK,OnPulses[3]);
    pulser p4(sw[4],CLK,OnPulses[4]);
    pulser p5(sw[5],CLK,OnPulses[5]);
    pulser p6(sw[6],CLK,OnPulses[6]);
    pulser p7(sw[7],CLK,OnPulses[7]);
    pulser p8(sw[8],CLK,OnPulses[8]);
    pulser p9(sw[9],CLK,OnPulses[9]);
    pulser p10(sw[10],CLK,OnPulses[10]);
    pulser p11(sw[11],CLK,OnPulses[11]);
    pulser p12(sw[12],CLK,OnPulses[12]);
    pulser p13(sw[13],CLK,OnPulses[13]);
    pulser p14(sw[14],CLK,OnPulses[14]);
    pulser p15(sw[15],CLK,OnPulses[15]);
    pulser p16(~sw[0],CLK,OffPulses[0]);
    pulser p17(~sw[1],CLK,OffPulses[1]);
    pulser p18(~sw[2],CLK,OffPulses[2]);
    pulser p19(~sw[3],CLK,OffPulses[3]);
    pulser p20(~sw[4],CLK,OffPulses[4]);
    pulser p21(~sw[5],CLK,OffPulses[5]);
    pulser p22(~sw[6],CLK,OffPulses[6]);
    pulser p23(~sw[7],CLK,OffPulses[7]);
    pulser p24(~sw[8],CLK,OffPulses[8]);
    pulser p25(~sw[9],CLK,OffPulses[9]);
    pulser p26(~sw[10],CLK,OffPulses[10]);
    pulser p27(~sw[11],CLK,OffPulses[11]);
    pulser p28(~sw[12],CLK,OffPulses[12]);
    pulser p29(~sw[13],CLK,OffPulses[13]);
    pulser p30(~sw[14],CLK,OffPulses[14]);
    pulser p31(~sw[15],CLK,OffPulses[15]);
    always @ (posedge CLK) begin
        if (OnPulses[0]) States[0] = 1;
        if (OnPulses[1]) States[1] = 1;
        if (OnPulses[2]) States[2] = 1;
        if (OnPulses[3]) States[3] = 1;
        if (OnPulses[4]) States[4] = 1;
        if (OnPulses[5]) States[5] = 1;
        if (OnPulses[6]) States[6] = 1;
        if (OnPulses[7]) States[7] = 1;
        if (OnPulses[8]) States[8] = 1;
        if (OnPulses[9]) States[9] = 1;
        if (OnPulses[10]) States[10] = 1;
        if (OnPulses[11]) States[11] = 1;
        if (OnPulses[12]) States[12] = 1;
        if (OnPulses[13]) States[13] = 1;
        if (OnPulses[14]) States[14] = 1;
        if (OnPulses[15]) States[15] = 1;
        if (OffPulses[0]) States[0] = 0;
        if (OffPulses[1]) States[1] = 0;
        if (OffPulses[2]) States[2] = 0;
        if (OffPulses[3]) States[3] = 0;
        if (OffPulses[4]) States[4] = 0;
        if (OffPulses[5]) States[5] = 0;
        if (OffPulses[6]) States[6] = 0;
        if (OffPulses[7]) States[7] = 0;
        if (OffPulses[8]) States[8] = 0;
        if (OffPulses[9]) States[9] = 0;
        if (OffPulses[10]) States[10] = 0;
        if (OffPulses[11]) States[11] = 0;
        if (OffPulses[12]) States[12] = 0;
        if (OffPulses[13]) States[13] = 0;
        if (OffPulses[14]) States[14] = 0;
        if (OffPulses[15]) States[15] = 0;
    end
    assign IsSwitchOn = States;
    assign SwitchOnPulses = OnPulses;
    assign SwitchOffPulses = OffPulses;
endmodule

module CommandMUX41(input [1:0] STATE, input [63:0] CMD0, input [63:0] CMD1, input [63:0] CMD2, input [63:0] CMD3, output [63:0] CMD);
    reg [63:0] cmd;
    always @(*) begin
        case (STATE)
            2'd1: cmd = CMD1;
            2'd2: cmd = CMD2;
            2'd3: cmd = CMD3;
            default: cmd = CMD0;
        endcase
    end
    assign CMD = cmd;
endmodule

module CommandAddressMUX41(input [1:0] STATE, input [6:0] ADDR0, input [6:0] ADDR1, input [6:0] ADDR2, input [6:0] ADDR3, output [6:0] ADDR);
    reg [6:0] addr;
    always @(*) begin
        case (STATE)
            2'd1: addr = ADDR1;
            2'd2: addr = ADDR2;
            2'd3: addr = ADDR3;
            default: addr = ADDR0;
        endcase
    end
    assign ADDR = addr;
endmodule

module PixAddr13bMUX41(input [1:0] STATE, input [12:0] ADDR0, input [12:0] ADDR1, input [12:0] ADDR2, input [12:0] ADDR3, output [12:0] ADDR);
    reg [12:0] addr;
    always @(*) begin
        case (STATE)
            2'd1: addr = ADDR1;
            2'd2: addr = ADDR2;
            2'd3: addr = ADDR3;
            default: addr = ADDR0;
        endcase
    end
    assign ADDR = addr;
endmodule

module Peripherals(
    input CLOCK, [2:0] clkReset, [4:0] slowBit, [4:0] btns,[15:0] sw,
    output [4:0] Clock,//100M, 6.25M, 20k, _flexible_
    output [15:0] swStates, [15:0] swOnPulses, [15:0] swOffPulses,
    output [4:0] btnStates, [4:0] btnPressPulses, [4:0] btnReleasePulses
    );
    QuadripleChannelClock qcc(CLOCK,clkReset,slowBit,Clock[3],Clock[2],Clock[1], Clock[0]);
    ButtonStates BS(btns, CLOCK, btnStates, btnPressPulses, btnReleasePulses);
    SwitchStates SS(sw, CLOCK, swStates, swOnPulses, swOffPulses);
    assign Clock[4] = CLOCK;
endmodule
