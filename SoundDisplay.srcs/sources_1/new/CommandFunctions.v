//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// Create Date: 03/25/2020 00:05:16 AM
// Design Name: FGPA Project for EE2026
// Module Name: [Functions] DrawPoint, DrawLine, DrawChar, DrawRect, DrawCirc, DrawSceneSprite, FillRect, FillCirc, 
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: These functions can be used to parse commands for drawing geometric shapes and texts conveniently
// Dependencies: NUL
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Must be included before use. All rights reserved by Li Bozhao.
//////////////////////////////////////////////////////////////////////////////////
function [63:0] DrawPoint;
    input [6:0] X;
    input [5:0] Y;
    input [15:0] COLOR; 
    begin
        DrawPoint[63] = 1;//Enable
        DrawPoint[62:59] = 4'd1;//PT
        DrawPoint[6:0] = X;
        DrawPoint[12:7] = Y;
        DrawPoint[28:13] = COLOR;
    end
endfunction

function [63:0] DrawLine;
    input [6:0] X1;
    input [5:0] Y1;
    input [6:0] X2;
    input [5:0] Y2;
    input [15:0] COLOR;
    begin
        DrawLine[63] = 1;//Enable
        DrawLine[62:59] = 4'd2;//LN
        DrawLine[6:0] = X1;
        DrawLine[12:7] = Y1;
        DrawLine[28:13] = COLOR;
        DrawLine[35:29] = X2;
        DrawLine[41:36] = Y2;
    end
endfunction

function [63:0] DrawChar;
    input [6:0] X;
    input [5:0] Y;
    input [19:0] CHR;
    input [15:0] COLOR;
    input POWER;
    begin
        DrawChar[63] = 1;//Enable
        DrawChar[62:59] = 4'd3;//CHR
        DrawChar[6:0] = X;
        DrawChar[12:7] = Y;
        DrawChar[28:13] = COLOR;
        DrawChar[48:29] = CHR;
        DrawChar[49] = POWER;
    end
endfunction

function [63:0] DrawRect;
    input [6:0] X1;
    input [5:0] Y1;
    input [6:0] X2;
    input [5:0] Y2;
    input [15:0] COLOR;
    begin
        DrawRect[63] = 1;//Enable
        DrawRect[62:59] = 4'd4;//RECT
        DrawRect[6:0] = X1;
        DrawRect[12:7] = Y1;
        DrawRect[28:13] = COLOR;
        DrawRect[35:29] = X2;
        DrawRect[41:36] = Y2;
    end
endfunction

function [63:0] DrawCirc;
    input [6:0] X;
    input [5:0] Y;
    input [4:0] R;
    input [15:0] COLOR;
    begin
        DrawCirc[63] = 1;//Enable
        DrawCirc[62:59] = 4'd5;//CIRC
        DrawCirc[6:0] = X;
        DrawCirc[12:7] = Y;
        DrawCirc[28:13] = COLOR;
        DrawCirc[33:29] = R;
    end
endfunction

function [63:0] DrawSceneSprite;
    input [6:0] X;
    input [5:0] Y;
    input [15:0] MCOLOR;
    input [6:0] INDEX;
    begin
        DrawSceneSprite[63] = 1;//Enable
        DrawSceneSprite[62:59] = 4'd6;//SPRSCN
        DrawSceneSprite[6:0] = X;
        DrawSceneSprite[12:7] = Y;
        DrawSceneSprite[28:13] = MCOLOR;
        DrawSceneSprite[35:29] = INDEX;
    end
endfunction

function [63:0] FillRect;
    input [6:0] X1;
    input [5:0] Y1;
    input [6:0] X2;
    input [5:0] Y2;
    input [15:0] COLOR;
    begin
        FillRect[63] = 1;//Enable
        FillRect[62:59] = 4'd7;//FRECT
        FillRect[6:0] = X1;
        FillRect[12:7] = Y1;
        FillRect[28:13] = COLOR;
        FillRect[35:29] = X2;
        FillRect[41:36] = Y2;
    end
endfunction

function [63:0] FillCirc;
    input [6:0] X;
    input [5:0] Y;
    input [4:0] R;
    input [15:0] COLOR;
    begin
        FillCirc[63] = 1;//Enable
        FillCirc[62:59] = 4'd8;//FCIRC
        FillCirc[6:0] = X;
        FillCirc[12:7] = Y;
        FillCirc[28:13] = COLOR;
        FillCirc[33:29] = R;
    end
endfunction
