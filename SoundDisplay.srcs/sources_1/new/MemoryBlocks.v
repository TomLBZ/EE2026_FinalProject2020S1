`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/16/2020 08:58:28 AM
// Design Name: FGPA Project for EE2026
// Module Name: MemoryBlocks, fifo, RAM
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module provides data structures to store relatively large amount of data and interact with them
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module DisplayRAM(input [12:0] readPix, input CLK, input Write, input [6:0] X, input [5:0] Y, input [15:0] COLOR, output STREAM);
    reg [15:0] DRAM [6:0][5:0];//DRAM[x][y]
    reg stream;
    reg dX, dY;
    always @(readPix) begin
        dX = readPix % 96;
        dY = readPix / 96;
        stream = DRAM[dX][dY];
    end
    assign STREAM = stream;
    always @(posedge CLK) begin
        if (Write) begin
            DRAM[X][Y] = COLOR;
        end
    end
endmodule

module DisplayCommands(input [63:0] Command, input CLK, output PixelSet, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);//64-bit command
    reg busy = 0;
    reg pixelSet = 0;
    reg [6:0] XO;
    reg [5:0] YO;
    reg [15:0] CO;
    wire commandHead = Command[62:59];//4 bit head
    wire OnCommand = Command[63];//enabling signal
    localparam IDLE = 0;
    localparam PT = 1;
    localparam LN = 2;
    localparam CHR = 3;
    localparam RECT = 4;
    localparam CIRC = 5;
    localparam PIC = 6;
    always @ (posedge CLK) begin
        if (OnCommand) begin
            case (commandHead)
                IDLE:begin 
                    pixelSet <= 0;
                    busy <= 0;
                end
                PT:begin //cmd[0:6]X,[7:12]Y,[13:28]C
                    pixelSet <= 1;
                    XO <= Command[0:6];
                    YO <= Command[7:12];
                    CO <= Command[13:28];
                    busy <= 0;
                end
                LN:begin //cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
                    pixelSet <= 1;
                    busy <= 1;
                end
                CHR:begin //cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:58]CHR//30-bit char set{[29:54]AZ,[55:58]", . [ ]"}
                end
                RECT:begin //cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
                end
                CIRC:begin //cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
                end
                PIC:begin //cmd[0:6]X1,[7:12]Y1,[13:19]X2,[20;25]Y2,[26:32]PX1,[33:38]PY1,[39:45]PX2,[46:51]PY2
                end
                default:begin //assume IDLE
                    pixelSet <= 0;
                    busy <= 0;
                end
            endcase
        end
    end
    assign BUSY = busy;
    assign PixelSet = pixelSet;
    assign X = XO;
    assign Y = YO;
    assign COLOR = CO;
endmodule

module CharBlocks(input [29:0] CHR, output [34:0] MAP);
    reg [34:0] map;
    always @ (CHR) begin
        case (CHR)
            0:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            1:begin map = 35'b11110_10001_10001_11110_10001_10001_11110; end//B
            2:begin map = 35'b01110_10001_10000_10000_10000_10001_01110; end//C
            3:begin map = 35'b11100_10010_10001_10001_10001_10010_11100; end//D
            4:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            5:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            6:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            7:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            8:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            9:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            10:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            11:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            12:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            13:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            14:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            15:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            16:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            17:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            08:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            19:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            20:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            21:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            22:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            23:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            24:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            25:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            26:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            27:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            28:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            29:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            default: begin map = 35'b0; end//Nothing
        endcase
    end
    assign MAP = map;
endmodule

module MemoryBlocks(

    );
endmodule