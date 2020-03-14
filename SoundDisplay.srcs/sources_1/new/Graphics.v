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

module CurrentPixel(input ReadCLK, input FIN, input [98303:0] Block, output [15:0] Pixel);
    reg [98303:0] block;
    always @ (posedge FIN) block = Block;
    reg [15:0] pixel;
    always @ (posedge ReadCLK) begin
        if (FIN) begin
            pixel = block[15:0];
            block = block >> 16;
        end else pixel = 16'h07E0;
    end
    assign Pixel = FIN ? pixel : 16'h07E0;
endmodule
module Graphics(
    input calcCLK,//this clock must be as fast as possible
    input readCLK,//this clock must be in sync with the API
    input onRefresh,
    input [3:0] state,
    input [4:0] R, [5:0] G, [4:0] B,
    input [2:0] stateInfo,//radius, width, etc.
    output [15:0] pixelData
    );
    localparam FlushScreen = 0;
    localparam GradientFlush = 1;
    localparam DrawLine = 2;
    localparam DrawLines = 3;
    localparam DrawRectangle = 4;
    localparam FillRectangle = 5;
    localparam DrawCircle = 6;
    localparam FillCircle = 7;
    localparam DrawPolygon = 8;
    localparam FillPolygon = 9;
    localparam DrawChar = 10;
    localparam DrawBorder = 11;
    localparam CheckerBoard = 12;
    function [15:0] RGBtoColor(input [4:0] r, input [5:0] g, input [4:0] b);
        RGBtoColor = {r, g, b};
    endfunction
    wire [15:0] Color = RGBtoColor(R,G,B);
    reg newBlock = 0;
    reg [6:0] X; reg [5:0] Y;
    reg FIN = 0;
    wire [98303:0] Block;
    integer x,y;
    BlockPixelSetter BPS(newBlock,FIN, X,  Y, Color, Block);
    CurrentPixel CP(readCLK, FIN, Block, pixelData);
    always @ (posedge onRefresh) begin
        newBlock = 0;
        FIN = 0;
        case (state)
            FlushScreen:begin 
                for (x = 0; x < 96; x = x + 1) begin
                    for (y = 0; y < 64; y = y + 1) begin
                        X <= x;
                        Y <= y;
                    end
                end
            end
            default:begin 
            end
        endcase
        FIN = 1;
    end
endmodule
