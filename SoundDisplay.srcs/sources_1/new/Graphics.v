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
    reg [6:0] XO;
    reg [5:0] YO;
    reg busy = 0;
    reg [6:0] x1;
    reg [6:0] x2;
    reg [6:0] x3;
    reg [5:0] y1;
    reg [5:0] y2;
    reg [5:0] y3;
    reg [12:0] pt[7:0];
    integer res [7:0];
    integer cross, square, tx, ty, minindex;
    reg [6:0] nx;
    reg [5:0] ny;
    reg [3:0] count;
    reg reached;
    always @ (XO,YO) begin
        if (busy) begin
            reached = X2 == nx && Y2 == ny;
            x1 = XO == 0 ? 0 : XO - 1;
            x2 = XO;
            x3 = XO == 95 ? 95 : XO + 1;
            y1 = YO == 0 ? 0 : YO - 1;
            y2 = YO;
            y3 = YO == 63 ? 63 : YO + 1;
            pt[0] = {y1,x1};
            pt[1] = {y1,x2};
            pt[2] = {y1,x3};
            pt[3] = {y2,x1};
            pt[4] = {y2,x3};
            pt[5] = {y3,x1};
            pt[6] = {y3,x2};
            pt[7] = {y3,x3};
            for (count = 0; count < 8; count = count + 1) begin
                cross = (X2 - X1) * (pt[count][6:0] - X1) + (Y2 - Y1) * (pt[count][12:7] - Y1);
                square = (X2 - X1) * (X2 - X1) + (Y2 - Y1) * (Y2 - Y1);
                if (cross > 0 && cross < square) begin//between end points
                    tx = X1 + (X2 - X1) * cross / square;
                    ty = Y1 + (Y2 - Y1) * cross / square;
                    res[count] = (pt[count][6:0] - tx) * (pt[count][6:0] - tx) + (ty - pt[count][12:7]) * (ty - pt[count][12:7]); //dist from line
                    minindex = ~count ? 0 : res[count] < res[count - 1] ? count : count - 1;
                end
            end
            nx = pt[minindex][6:0];
            ny = pt[minindex][12:7];
        end else begin
            for (count = 0; count < 8; count = count + 1) res[count] = 0;
            reached = 0;
            nx = 0;
            ny = 0;
            minindex = 0;
            XO = 0;
            YO = 0;
        end
    end
    always @ (posedge CLK) begin
        if (ON) begin
            if (~busy) begin
                busy = 1;
                XO <= X1;
                YO <= Y1;
            end else if (~reached) begin //(x-x1)/(y-y1)=(x2-x1)/(y2-y1)
                XO <= nx;
                YO <= ny;
                busy = 1;
            end else begin
                XO <= nx;
                YO <= ny;
                busy = 0;
            end
        end
    end
    assign BUSY = busy;
    assign X = XO;
    assign Y = YO;
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
    DisplayCommandCore DCMD(Cmd, WCLK, pixSet, CmdX, CmdY, CmdCol, CmdBusy);
    PixelSetter PSET(WCLK,pixSet,CmdX,CmdY,CmdCol,psX,psY,psC,write);
    DisplayRAM DRAM(Pix, WCLK, write, psX, psY, psC, STREAM);
    DrawLine DL(5, 5, 60, 40, {0,32,32}, LNcmd);
    always @ (sw) begin//redraw onto the DRAM as a new frame
        if (sw[0]) begin
            Cmd = LNcmd;
        end
    end
endmodule

module MyGraphics(
    input onRefresh,
    input [3:0] state,
    input [4:0] R, [5:0] G, [4:0] B,
    input [31:0] Info,//radius, width, etc.
    input [12:0] currentPixel,
    output [15:0] pixelData
    );
    localparam DefaultGreen = 0;
    localparam FlushScreen = 1;
    localparam GradientFlush = 2;
    localparam DrawLine = 3;
    localparam DrawCoordinateSystem = 4;
    localparam DrawRectangle = 5;
    localparam FillRectangle = 6;
    localparam DrawCircle = 7;
    localparam FillCircle = 8;
    localparam DrawPolygon = 9;
    localparam FillPolygon = 10;
    localparam DrawChar = 11;
    localparam DrawBorder = 12;
    localparam CheckerBoard = 13;
    localparam VolumeBars = 14;
    localparam BlueVolTask = 15;
    function [15:0] RGBtoColor(input [4:0] r, input [5:0] g, input [4:0] b);
        RGBtoColor = {r, g, b};
    endfunction
    wire [15:0] Color = RGBtoColor(R,G,B);
    wire [15:0] _Color = RGBtoColor(31 - R, 63 - G, 31 - B);
    reg [15:0] color; reg [6:0] rX; reg [5:0] rY;
    reg [3:0] evalParam;
    always @ (currentPixel) begin
        rY <= (currentPixel / 96);
        rX <= (currentPixel - rY * 96);
        case (state)
            DefaultGreen: begin
                color <= 16'h07E0;
            end
            FlushScreen:begin 
                color <= Color;
            end
            GradientFlush:begin
                color <= RGBtoColor(R - rX / 3, G - rY, B);
            end
            DrawLine:begin//Info:P1([6:0],[12:7]),P2([19:13],[25:20])-- x=x1+(y-y1)(x2-x1)/(y2-y1)
                color <= rX==Info[6:0]+(rY-Info[12:7])*(Info[19:13]-Info[6:0])/(Info[25:20]-Info[12:7]) ? Color : _Color;
            end
            DrawCoordinateSystem:begin
                color <= rX==47 || rY==31 ? Color : _Color;
            end
            DrawRectangle: begin//Info:TL([6:0],[12:7]),BR([19:13],[25:20])
                evalParam[0] = (rX==Info[6:0]||rX==Info[19:13])&&(rY<Info[25:20]&&rY>Info[12:7]);
                evalParam[1] = (rX>Info[6:0]&&rX<Info[19:13])&&(rY==Info[25:20]||rY==Info[12:7]);
                color = evalParam[0] | evalParam[1] ? Color : _Color;
            end
            FillRectangle:begin//Info:TL([6:0],[12:7]),BR([19:13],[25:20])
                evalParam[0] = rX>Info[6:0] && rX<Info[19:13];
                evalParam[1] = rY>Info[12:7] && rY<Info[25:20];
                color = evalParam[0] & evalParam[1] ? Color : _Color;
            end
            DrawCircle:begin//Info:C([6:0],[12:7]),R[16:13]
                color <= rX*rX + Info[6:0]*Info[6:0] - 2*rX*Info[6:0] + rY*rY + Info[12:7]*Info[12:7] - 2*rY*Info[12:7] == Info[16:13]*Info[16:13] ? Color : _Color;
            end
            FillCircle:begin//Info:C([6:0],[12:7]),R[16:13]
                color <= rX*rX + Info[6:0]*Info[6:0] - 2*rX*Info[6:0] + rY*rY + Info[12:7]*Info[12:7] - 2*rY*Info[12:7] < Info[16:13]*Info[16:13] ? Color : _Color;
            end
            DrawPolygon:begin
                
            end
            FillPolygon:begin
            
            end
            DrawChar:begin//Info:T1([6:0],[12:7]),T2([19:13],[25:20])
            
            end
            DrawBorder:begin//Info:TL([6:0],[12:7]),BR([19:13],[25:20]),W[29:26]
                evalParam[0] = (rX>(Info[6:0]-Info[29:26]))&&(rX<(Info[19:13]+Info[29:26]));//|.........|
                evalParam[1] = (rX<(Info[6:0]+Info[29:26]))||(rX>(Info[19:13]-Info[29:26]));//...|   |...
                evalParam[2] = (rY>(Info[12:7]-Info[29:26]))&&(rY<(Info[25:20]+Info[29:26]));//|.........|
                evalParam[3] = (rY<(Info[12:7]+Info[29:26]))||(rY>(Info[25:20]-Info[29:26]));//...|   |...              
                color <= (evalParam[0] && evalParam[2]) && (evalParam[1] || evalParam[3]) ? _Color : Color;
            end
            CheckerBoard: begin
                color <= ((rX / 16) % 2) ^ ((rY / 16) % 2) ? _Color : Color;
            end
            VolumeBars:begin
            
            end
            BlueVolTask: begin//Info:[4:0]blue
                color <= Info[4:0];
            end
            default:begin 
                color <= 16'h07E0;
            end
        endcase
    end    
    assign pixelData = color;
endmodule

