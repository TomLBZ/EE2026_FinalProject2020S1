`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/13/2020 09:51:11 AM
// Design Name: FGPA Project for EE2026
// Module Name: Graphics
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module can be used to draw geometric shapes and texts conveniently.
// 
// Dependencies: PixelSetter
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
module Graphics(
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

