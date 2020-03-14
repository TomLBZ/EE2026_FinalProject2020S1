`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/13/2020 09:51:11 AM
// Design Name: FGPA Project for EE2026
// Module Name: PixelSetter
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module interfaces the API (Oled_Display.v) and provides the interface to set display by pixel
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RamBuilder(input [5:0] Y, input [1535:0] Line, input [98303:0] oldRam, output [98303:0] newRam);
    assign newRam = oldRam & (Line << Y * 1536);
endmodule
module LineBuilder(input [6:0] X, input [15:0] Color, input [1535:0] oldLine, output [1535:0] newLine);
    assign newLine = oldLine & (Color << X * 16);
endmodule
module BlockPixelSetter(
    input NEW,//suggesting a new block
    input FIN,//suggesting output
    input [6:0] X, [5:0] Y, [15:0] Color,
    output [98303:0] Block
    );
    reg xcounter = 0;
    reg ycounter = 0;
    reg [1535:0] currentLine = 0;
    wire [1535:0] newLine;
    reg [98303:0] block = 0;
    wire [98303:0] newblock;
    LineBuilder LB(X,Color,currentLine,newLine);
    RamBuilder RB(Y,newLine,block,newblock);
    always @ (newLine) currentLine = newLine;
    always @ (newblock) block = newblock;
    always @ (posedge NEW) block = 0;
    assign Block = FIN ? block : 0;
endmodule
