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

module ReadOnlyBadAppleCompressedData(input RCLK, input [17:0] ADDR, output [7:0] DATA);
    reg [7:0] BAM [105433:0];//105434 cmds
    parameter MEM_INIT_FILE = "BadAppleMem.mem";
    initial begin
        if (MEM_INIT_FILE != "") begin
            $readmemh(MEM_INIT_FILE, BAM);
        end
    end
    reg [7:0] data = 7'b0;
    always @ (posedge RCLK) begin
        if (ADDR < 18'd105434) data = BAM[ADDR];
        else data = 8'b0;
    end
    assign DATA = data;
endmodule

module BadApple(input CLK, input ON, input PAUSE, input Clk10Hz, output Write, output [12:0] ADDR, output [15:0] COLOR);
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE = 0;
    reg [12:0] PosOnFrame = 13'b0;
    wire DONEFRAME = PosOnFrame == 11'd1536;
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
    ReadOnlyBadAppleCompressedData BAD(CLK, AddrCount, Data);
    wire [15:0] C = Data[7] ? 16'b1111111111111111 : 16'd0;
    wire [6:0] LEN = Data[6:0];//63:0
    wire [5:0] y = PosOnFrame / 7'd48;
    wire [6:0] x = PosOnFrame - y * 7'd48;//[0,0],[47,31]
    wire [5:0] y2 = y << 1;//0->0, 31->62
    wire [6:0] x2 = x << 1;//0->0, 47->94
    wire [12:0] Addr1 = y2 * 7'd48 + x2;//[0,0]->[0,0];[47,31]->[94,62]
    wire [12:0] Addr2 = (y2 + 1'b1) * 7'd96 + x2;//[0,0]->[0,1];[47,31]->[94,63]
    wire [12:0] Addr3 = y2 * 7'd96 + x2 + 1'b1;//[0,0]->[1,0];[47,31]->[95,62]
    wire [12:0] Addr4 = (y2 + 1'b1) * 7'd96 + x2 + 1'b1;//[0,0]->[1,1];[47,31]->[95,63]
    reg [1:0] vDup = 2'd3;
    PixAddr13bMUX41 PAMUX(vDup,Addr1,Addr2,Addr3,Addr4,ADDR);
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
                if (AddrCount == 18'd105434) AddrCount = 18'b0;
                else if (PosOnFrame == PosUBound) begin
                    AddrCount = AddrCount + 1'd1;
                    PosUBound = PosOnFrame + LEN;
                end
            end        
        end
    end
    assign COLOR = C;
endmodule
