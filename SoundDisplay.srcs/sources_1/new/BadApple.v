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

module BadApple(input CLK, input ON, input PAUSE, input Clk10Hz, output Write, output [12:0] ADDR, output [15:0] COLOR);
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
                if (PAUSE | DONEFRAME) STATE <= STP;//if done then stop
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
    ReadOnlyBadAppleCompressedData BAD(CLK, Write,0, AddrCount, Data, Data);
    wire [15:0] C = Data[7] ? 16'b0 : 16'd65535;
    wire [6:0] LEN = Data[6:0];//63:0
    wire [5:0] y = PosOnFrame / 7'd48;//0-63
    wire [6:0] x = PosOnFrame - y * 7'd48;//[0,0],[47,63]
    wire [6:0] x2 = x << 1;//[0,94]
    wire [12:0] Addr1 = y * 7'd96 + x2;//[0,0]->[0,0];[47,63]->[94,63]
    wire [12:0] Addr2 = y * 7'd96 + x2 + 1'b1;//[0,0]->[0,1];[47,63]->[95,63]
    reg vDup = 2'd1;
    assign ADDR = vDup ? Addr1 : Addr2;
    reg [11:0] Frame = 12'b0;
    reg [11:0] NextFrame = 12'b0;
    reg [12:0] PosUBound = 13'd127;
    always @ (posedge Clk10Hz) begin
        if (Write) Frame = NextFrame;
    end
    always @ (posedge CLK) begin
        if (Write) begin
            if (Frame == NextFrame) begin
                NextFrame = NextFrame + 1;
                if(NextFrame == 12'd2192) NextFrame = 1'b0;//max 2191
                PosOnFrame = 1'b0;
                PosUBound = PosOnFrame + LEN;
            end else begin
                if (vDup == 2'd0) PosOnFrame = PosOnFrame + 1;
                vDup = vDup + 1;
                if (DONEFRAME) PosOnFrame = 1'b0;
                if (AddrCount == 18'd159970) AddrCount = 18'b0;
                else if (PosOnFrame == PosUBound) begin
                    AddrCount = AddrCount + 1'd1;
                    PosUBound = PosOnFrame + LEN;
                end
            end        
        end
    end
    assign COLOR = C;
endmodule
