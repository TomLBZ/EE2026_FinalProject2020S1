`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2020 09:55:35 AM
// Design Name: 
// Module Name: BadApple
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module plays BadApple!
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module PixelFromPos(input [7:0] Data, input [12:0] PosOnFrame, output [6:0] X1, output [6:0] X2, output [5:0] Y, output [15:0] C, output [6:0] LEN);
    wire [6:0] cX = PosOnFrame / 7'd64;
    wire [6:0] cY = PosOnFrame - 7'd64 * cX;
    wire [6:0] cX1 = cX << 1'd1;//cx * 2
    wire [6:0] cX2 = cX1 + 1'd1;
    assign X1 = cX1;
    assign X2 = cX2;
    assign Y = cY;
    assign C = Data[7] ? 16'b0 : 16'd65535;
    assign LEN = Data[6:0];
endmodule

module BadAppleCore(input CLK, input ON, input PAUSE, input Clk10Hz, output Write, output [6:0] X, output [5:0] Y, output [15:0] C);
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE = 0;
    reg [12:0] PosOnFrame = 13'b0;
    wire DONEFRAME = PosOnFrame == 12'd3072;
    always @ (posedge CLK) begin//change state
        case (STATE)
            IDL: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            STR: begin
                if (PAUSE | DONEFRAME) begin
                    STATE <= STP;//if done then stop
                end
                else STATE <= STR;//else start
            end
            STP: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            default: STATE <= IDL;//default idle
        endcase
    end
    assign Write = (STATE == STR);
    reg [17:0] AddrCount;
    wire [7:0] Data;
    ReadOnlyBadAppleCompressedData BAD(CLK, Write,0, AddrCount, , Data);
    wire [6:0] LEN;//63:0
    wire [6:0] x1;
    wire [6:0] x2;
    PixelFromPos PFP(Data, PosOnFrame, x1, x2, Y, C, LEN);
    reg vDup = 2'd1;
    assign X = vDup ? x1 : x2;
    reg [11:0] Frame = 12'b0;
    reg [11:0] NextFrame = 12'b0;
    reg [12:0] StartPos = 0;
    wire [12:0] PosUBound = StartPos + LEN;
    always @ (posedge Clk10Hz) begin
        if (Write) Frame = NextFrame;
    end
    always @ (posedge CLK) begin
        if (Write) begin
            if (Frame == NextFrame) begin
                NextFrame = NextFrame + 1;
                if(NextFrame == 12'd2192) NextFrame = 1'b0;//max 2191
                PosOnFrame = 1'b0;
                StartPos = 0;
            end else begin
                vDup = vDup + 1;
                if (DONEFRAME) PosOnFrame = 1'b0;
                if (AddrCount == 18'd179996) AddrCount = 18'b0;//18'd159970
                else if (PosOnFrame == PosUBound && vDup) begin
                    StartPos = StartPos + LEN + 1'd1;
                    AddrCount = AddrCount + 1'd1;
                end
                if (vDup) PosOnFrame = PosOnFrame + 1;
                if (PosOnFrame == 12'd3072) PosOnFrame = 0;
            end        
        end
    end
endmodule
