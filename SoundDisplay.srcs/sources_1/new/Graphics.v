`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/13/2020 09:51:11 AM
// Design Name: FGPA Project for EE2026
// Module Name: PixelSetter, DrawPoint, DrawLine, DrawChar, DrawRect, DrawCirc, Graphics
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module can be used to draw geometric shapes and texts conveniently.
// 
// Dependencies: MemoryBlocks.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module PixelSetter(input CLK, input ON, input [6:0] X, input [5:0] Y, input [15:0] COLOR, output [6:0] XO, output [5:0] YO, output [15:0] CO, output WR);
    reg write = 0;
    always @ (posedge CLK) write = ON ? 1 : 0;
    assign XO = X;
    assign YO = Y;
    assign CO = COLOR;
    assign WR = write;
endmodule

module DrawPoint(input [6:0] X, input [5:0] Y, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X,[7:12]Y,[13:28]C
    always @ (X, Y, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd1;//PT
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
    end
    assign CMD = cmd;
endmodule

module OnPointCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] pX = CMD[6:0];
    wire [5:0] pY = CMD[12:7];
    assign COLOR = CMD[28:13];
    reg busy = 0;
    reg completed = 0;
    reg [6:0] XO;
    reg [5:0] YO;
    always @ (XO, YO) begin
        if (busy) completed = 1;
        else completed = 0;
    end
    always @ (posedge CLK) begin
        if (ON) begin
            if (~busy) begin
                XO <= pX;
                YO <= pY;
                busy = 1;
            end else begin
                if (completed) busy = 0;
            end
        end else begin
            XO <= 0;
            YO <= 0;
        end
    end
    assign BUSY = busy;
    assign X = XO;
    assign Y = YO;
endmodule

module DrawLine(input [6:0] X1, input [5:0] Y1, input [6:0] X2, input [5:0] Y2, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    always @ (X1, Y1, X2, Y2, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd2;//LN
        cmd[6:0] <= X1;
        cmd[12:7] <= Y1;
        cmd[28:13] <= COLOR;
        cmd[35:29] <= X2;
        cmd[41:36] <= Y2;
    end
    assign CMD = cmd;
endmodule

module OnLineCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] X1 = CMD[6:0];
    wire [5:0] Y1 = CMD[12:7];
    wire [6:0] X2 = CMD[35:29];
    wire [5:0] Y2 = CMD[41:36];
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] END = 2;//end drawing
    reg [1:0] STATE;//current state
    reg signed [8:0] e;//error
    reg signed [7:0] x;//x
    reg signed [6:0] y;//y
    wire loop = (STATE == STR);//if started, then loops
    wire signed [7:0] dX = X2 - X1;//signed, msb is the sign, actually is [6:0] X data.
    wire signed [7:0] rSignX = ~(dX[7]);//reverse sign of dX. if dX was positive, this would return 1.
    wire signed [7:0] DX = (!rSignX) ? -dX : dX;//if dX was positive, DX = dX. else DX = -dX. -> always positive
    wire signed [6:0] dY = Y2 - Y1;//signed, msb is the sign, actually is [5:0] Y data.
    wire signed [6:0] rSignY = ~(dY[6]);//reverse sign of dY. if dY was positive, this would return 1.
    wire signed [6:0] DY = rSignY ? -dY : dY;//if dY was positive, DY = -dY. else DY = dY. -> always negative
    wire signed [8:0] e2 = e << 1;//left shift, equivalent to times 2.
    wire e2bDY = (e2 > DY) ? 1 : 0;//is 2e bigger than DY?
    wire e2sDX = (e2 < DX) ? 1 : 0;//is 2e smaller than DX?
    wire signed [8:0] ei = e2bDY ? (e + DY) : e;//next e
    wire signed [8:0] eii = e2sDX ? (ei + DX) : e;//next next e
    wire signed [8:0] E = loop ? eii : (DX + DY);//get next correct value of e
    wire signed [7:0] XA = rSignX ? (x + 1) : (x - 1);//if dX positive, XA = x increments, else decrements
    wire signed [7:0] XB = e2bDY ? XA : x;//if 2e bigger than DY (eg. ini, DY < 0) then XB = XA. else x.
    wire signed [7:0] NX = loop ? XB: X1;//next x is XB unless not in loop
    wire signed [6:0] YA = rSignY ? (y + 1) : (y - 1);//if dY positive, YA = y increments, else decrements.
    wire signed [6:0] YB = e2sDX ? YA : y;//if 2e smaller than DX (eg. ini, DX > 0) then YB = YA. else y.
    wire signed [6:0] NY = loop ? YB : Y1;//next y is YB unless not in loop
    wire DONE = (x == X2) && (y == Y2);//reached end point
    always @ (posedge CLK) begin//update variable registers
        e <= E;
        x <= NX;
        y = NY;
    end
    always @ (posedge CLK) begin//change state
        case (STATE)
            IDL: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            STR: begin
                if (DONE) STATE <= END;//if done then stop
                else STATE <= STR;//else start
            end
            END: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            default: STATE <= IDL;//default idle
        endcase
    end
    assign BUSY = loop;//if looping then busy
    assign X = x[6:0];//without the sign
    assign Y = y[5:0];//without the sign
endmodule

module DrawChar(input [6:0] X, input [5:0] Y, input [29:0] CHR, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd; //cmd[0:6]X,[7:12]Y,[13:28]C,[29:58]CHR//30-bit char set{[29:54]AZ,[55:58]", . [ ]"}
    always @ (X, Y, CHR, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd3;//CHR
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
        cmd[58:29] <= CHR;
    end
    assign CMD = cmd;
endmodule

module DrawRect(input [6:0] X1, input [5:0] Y1, input [6:0] X2, input [5:0] Y2, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    always @ (X1, Y1, X2, Y2, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd4;//RECT
        cmd[6:0] <= X1;
        cmd[12:7] <= Y1;
        cmd[28:13] <= COLOR;
        cmd[35:29] <= X2;
        cmd[41:36] <= Y2;
    end
    assign CMD = cmd;
endmodule

module DrawCirc(input [6:0] X, input [5:0] Y, input [4:0] R, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    always @ (X, Y, R, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd5;//CIRC
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
        cmd[33:29] <= R;
    end
    assign CMD = cmd;
endmodule

module Graphics(input [14:0] sw, input onRefresh, input WCLK, input [12:0] Pix, output [15:0] STREAM);
    reg [63:0] Cmd;
    wire [63:0] PTcmd;
    wire [63:0] LNcmd;
    wire [6:0] CmdX;
    wire [5:0] CmdY;
    wire [15:0] CmdCol;
    wire pixSet;
    wire CmdBusy;
    wire [6:0] psX;
    wire [5:0] psY;
    wire [15:0] psC;
    wire write;
    wire [3:0] swState;
    swBitsToState swB2S(sw,swState);
    DisplayCommandCore DCMD(Cmd, WCLK, pixSet, CmdX, CmdY, CmdCol, CmdBusy);
    PixelSetter PSET(WCLK,pixSet,CmdX,CmdY,CmdCol,psX,psY,psC,write);
    DisplayRAM DRAM(Pix, WCLK, write, psX, psY, psC, STREAM);
    DrawPoint DP(7'd48, 6'd32, {5'd31,6'd63,5'd0}, PTcmd);
    DrawLine DL(7'd50, 6'd16, 7'd60, 6'd48, {5'd0,6'd32,5'd31}, LNcmd);
    always @ (*) begin//redraw onto the DRAM as a new frame
        if(~CmdBusy) begin
            case (swState)
                4'd1: begin Cmd = PTcmd; end // 1 - point
                4'd2: begin Cmd = LNcmd; end // 2 - line
                4'd3: begin end
                4'd4: begin end
                default: begin Cmd = 5'b10000 << 59; end // 0 - idle
            endcase
        end
    end
endmodule