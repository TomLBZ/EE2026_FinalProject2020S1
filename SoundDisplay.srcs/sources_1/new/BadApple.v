`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// Create Date: 03/13/2020 09:55:35 AM
// Design Name: FGPA Project for EE2026
// Module Name: PixelFromPos, BadAppleCore
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module plays BadApple!
// Dependencies: MemoryBlocks.v
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Developed by Li Bozhao, all rights reserved.
//////////////////////////////////////////////////////////////////////////////////
module PixelFromPos(input [7:0] Data, input [12:0] PosOnFrame, output [6:0] X1, output [6:0] X2, output [5:0] Y, output [15:0] C, output [6:0] LEN);
    wire [6:0] cX = (PosOnFrame + 1'b1) / 7'd64;
    wire [6:0] cY = (PosOnFrame + 1'b1) - 7'd64 * cX;
    wire [6:0] cX1 = cX << 1'd1;//cx * 2
    wire [6:0] cX2 = cX1 + 1'd1;
    assign X1 = cX1;
    assign X2 = cX2;
    assign Y = cY;
    assign C = Data[7] ? 16'd65535 : 16'd0;
    assign LEN = Data[6:0];
endmodule

module BadAppleCore(input CLK, input ON, input PAUSE, input Clk10Hz, output Write, output [6:0] X, output [5:0] Y, output [15:0] C, output [15:0] DebugLED);
    reg [17:0] AddrCount;
    wire [7:0] Data;
    ReadOnlyBadAppleCompressedData BAD(CLK, Write,0, AddrCount, , Data);
    wire [6:0] LEN;//63:0
    wire [6:0] x1;
    wire [6:0] x2;
    reg [12:0] PosOnFrame = 13'b0;
    reg [12:0] PixelCounter = 13'b0;
    PixelFromPos PFP(Data, PosOnFrame, x1, x2, Y, C, LEN);
    reg [2:0] vDup = 3'd0;
    assign X = vDup[2] ? x1 : x2;
    reg [12:0] StartPos = 0;
    wire [12:0] PosUBound = StartPos + LEN;
    wire DONEFRAME = PixelCounter >= 12'd3072;
    reg [11:0] Frame = 12'b0 - 1'b1;
    reg [11:0] NextFrame = 12'b0;
    always @ (posedge Clk10Hz) if(ON) Frame = NextFrame;
    assign Write = Frame == NextFrame;
    always @ (posedge CLK) begin
        if (ON) begin
            if (DONEFRAME) begin
                if(NextFrame < 12'd2191)NextFrame = NextFrame + 1;//after adding max will be 2191
                else NextFrame = 1'b0;//max 2191
                PosOnFrame = 1'b0;
                PixelCounter = 1'b0;
                StartPos = 0;
                vDup = 3'd0;
            end
            if (Write) begin
                vDup = vDup + 1;
                if (vDup == 3'b000) begin
                    PixelCounter = PixelCounter + 1;
                    if (PixelCounter < 12'd3072) PosOnFrame = PixelCounter;
                    if (PosOnFrame >= PosUBound) begin 
                        StartPos = StartPos + LEN + 1'd1; 
                        if (AddrCount < 18'd179995) AddrCount = AddrCount + 1'd1;//after adding max will be 179995
                        else AddrCount = 18'b0;
                    end
                end
            end    
        end 
    end
    //assign DebugLED[12:1] = Frame;
    //assign DebugLED[0] = Write;
endmodule
