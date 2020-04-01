`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// Create Date: 03/16/2020 08:58:28 AM
// Design Name: FGPA Project for EE2026
// Module Name: DisplayRAM, CommandQueue, DisplayCommandCore, CharBlocks, SceneSpriteBlocks
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module provides data structures to store relatively large amount of data and interact with them.The screen and the user input are decoupled here.
// Dependencies: NULL
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module DisplayRAM(input [12:0] readPix, input AsyncReadCLK, input WCLK, input Write, input [6:0] X, input [5:0] Y, input [15:0] COLOR, output [15:0] STREAM);
    reg [15:0] DRAM [6143:0];
    reg [15:0] stream;
    reg [12:0] c;
    initial begin
        stream = 16'd0;
        for (c = 0; c < 13'd6144;c = c + 1) begin
            DRAM[c] = 16'd0;
        end
    end
    always @(posedge AsyncReadCLK) begin
        stream = DRAM[readPix]; 
    end
    assign STREAM = stream;
    always @(posedge WCLK) begin
        if (Write) begin
            DRAM[Y * 96 + X] = COLOR;
        end
    end
endmodule

module CommandQueue #(parameter size = 128) (input [63:0] CMD, input RCLK, input [6:0] RADDR, input WCLK, input [6:0] WADDR, output [63:0] CurrentCommand);
    reg [63:0] CMDQ [size - 1:0];
    reg [63:0] cCmd;
    reg [7:0] c;
    initial begin
        cCmd = 64'b0;
        for (c = 0; c < size; c = c + 1) begin
            CMDQ[c] = 64'b0;
        end
    end
    always @ (posedge RCLK) begin
        cCmd = CMDQ[RADDR];
    end
    assign CurrentCommand = cCmd;
    always @ (posedge WCLK) begin
        CMDQ[WADDR] = CMD;
    end
endmodule

module CharBlocks(input [19:0] CHR, output [34:0] MAP);
    reg [34:0] map = 35'd0;
    always @ (*) begin
        case (CHR)
            20'd0:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            20'd1:begin map = 35'b11110_10001_10001_11110_10001_10001_11110; end//B
            20'd2:begin map = 35'b01110_10001_10000_10000_10000_10001_01110; end//C
            20'd3:begin map = 35'b11100_10010_10001_10001_10001_10010_11100; end//D
            20'd4:begin map = 35'b11111_10000_10000_11110_10000_10000_11111; end//E
            20'd5:begin map = 35'b11111_10000_10000_11110_10000_10000_10000; end//F
            20'd6:begin map = 35'b01110_10001_10000_10011_10001_10001_01110; end//G
            20'd7:begin map = 35'b10001_10001_10001_11111_10001_10001_10001; end//H
            20'd8:begin map = 35'b01110_00100_00100_00100_00100_00100_01110; end//I
            20'd9:begin map = 35'b01110_00100_00100_00100_10100_10100_01100; end//J
            20'd10:begin map = 35'b10001_10010_10100_11000_10100_10010_10001; end//K
            20'd11:begin map = 35'b10000_10000_10000_10000_10000_10000_11111; end//L
            20'd12:begin map = 35'b01010_01010_10101_10101_10101_10001_10001; end//M
            20'd13:begin map = 35'b10001_11001_11001_10101_10011_10011_10001; end//N
            20'd14:begin map = 35'b01110_10001_10001_10001_10001_10001_01110; end//O
            20'd15:begin map = 35'b11111_10001_10001_11111_10000_10000_10000; end//P
            20'd16:begin map = 35'b01100_10010_10010_10010_10010_10110_01111; end//Q
            20'd17:begin map = 35'b11111_10001_10001_11110_10100_10010_10001; end//R
            20'd08:begin map = 35'b01110_10001_10000_01110_00001_10001_01110; end//S
            20'd19:begin map = 35'b11111_00100_00100_00100_00100_00100_00100; end//T
            20'd20:begin map = 35'b10001_10001_10001_10001_10001_10001_01110; end//U
            20'd21:begin map = 35'b10001_10001_10001_10001_10001_01010_00100; end//V
            20'd22:begin map = 35'b10001_10001_10101_10101_10101_01010_01010; end//W
            20'd23:begin map = 35'b10001_10001_01010_00100_01010_10001_10001; end//X
            20'd24:begin map = 35'b10001_10001_01010_00100_00100_00100_00100; end//Y
            20'd25:begin map = 35'b11111_00001_00010_00100_01000_10000_11111; end//Z
            20'd26:begin map = 35'b00000_00000_00000_00000_01100_00100_01000; end//,
            20'd27:begin map = 35'b00000_00000_00000_00000_00000_01100_01100; end//.
            20'd28:begin map = 35'b00110_00100_00100_00100_00100_00100_00110; end//[
            20'd29:begin map = 35'b01100_00100_00100_00100_00100_00100_01100; end//]
            default: begin map = 35'b0; end//Nothing
        endcase
    end
    assign MAP = map;
endmodule

module SceneSpriteBlocks(input [6:0] SCN, output reg [15:0] COLOR[63:0]);
    localparam [2:0] GRASS = 0;
    localparam [2:0] BRICK = 1;    
    localparam [2:0] CACTUS = 2;
    localparam [2:0] STEVE = 3;
    localparam [3:0] MOTHCOBBLESTONE = 4;
    always @(*) begin
        case (SCN)
            GRASS: COLOR = {{5'd12,6'd32,5'd8},{5'd12,6'd32,5'd8},{5'd12,6'd32,5'd8},{5'd8,6'd32,5'd8},{5'd12,6'd40,5'd8},{5'd12,6'd32,5'd8},{5'd12,6'd32,5'd8},{5'd8,6'd24,5'd8},
                            {5'd12,6'd40,5'd8},{5'd12,6'd40,5'd8},{5'd12,6'd32,5'd8},{5'd12,6'd32,5'd8},{5'd12,6'd32,5'd8},{5'd12,6'd40,5'd8},{5'd12,6'd16,5'd8},{5'd8,6'd32,5'd8},
                            {5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd12,6'd16,5'd8},{5'd16,6'd24,5'd8},{5'd12,6'd16,5'd8},{5'd12,6'd16,5'd8},{5'd16,6'd24,5'd8},{5'd12,6'd16,5'd8},
                            {5'd24,6'd32,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd32,5'd16},{5'd16,6'd24,5'd8},{5'd24,6'd32,5'd8},{5'd24,6'd32,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},
                            {5'd20,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd12,6'd16,5'd8},
                            {5'd20,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd24,6'd32,5'd8},{5'd24,6'd32,5'd8},{5'd12,6'd16,5'd8},{5'd24,6'd32,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd32,5'd16},
                            {5'd16,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd24,6'd32,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd24,6'd32,5'd8},
                            {5'd20,6'd24,5'd8},{5'd12,6'd16,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd24,6'd32,5'd8},{5'd16,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd20,6'd24,5'd8}};
            BRICK: COLOR = {{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},
                            {5'd16,6'd16,5'd8},{5'd12,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},
                            {5'd16,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},
                            {5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},
                            {5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd24,6'd24,5'd8},
                            {5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd12,6'd16,5'd8},{5'd12,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},
                            {5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},{5'd20,6'd24,5'd8},
                            {5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd20,6'd24,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8},{5'd16,6'd16,5'd8}};
            CACTUS: COLOR ={{5'd31,6'd63,5'd31},{5'd4,6'd32,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd8},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd8},{5'd0,6'd24,5'd0},
                            {5'd0,6'd0,5'd0},{5'd0,6'd24,5'd0},{5'd0,6'd32,5'd0},{5'd0,6'd24,5'd0},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd8},{5'd0,6'd0,5'd0},
                            {5'd31,6'd63,5'd31},{5'd0,6'd32,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd0},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd0},{5'd4,6'd32,5'd8},{5'd0,6'd24,5'd0},
                            {5'd0,6'd0,5'd0},{5'd4,6'd32,5'd0},{5'd4,6'd32,5'd0},{5'd4,6'd32,5'd8},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd8},{5'd0,6'd0,5'd0},
                            {5'd31,6'd63,5'd31},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd0},{5'd4,6'd32,5'd0},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd0},{5'd0,6'd24,5'd0},
                            {5'd0,6'd0,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd0},{5'd0,6'd24,5'd0},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd8},{5'd0,6'd0,5'd0},
                            {5'd0,6'd0,5'd0},{5'd0,6'd24,5'd0},{5'd4,6'd32,5'd8},{5'd0,6'd32,5'd0},{5'd0,6'd0,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd0},{5'd0,6'd24,5'd0},
                            {5'd31,6'd63,5'd31},{5'd4,6'd32,5'd8},{5'd0,6'd32,5'd0},{5'd0,6'd24,5'd0},{5'd0,6'd16,5'd0},{5'd4,6'd32,5'd8},{5'd4,6'd32,5'd8},{5'd0,6'd24,5'd0}};
            STEVE: COLOR = {{5'd5,6'd7,5'd1},{5'd5,6'd7,5'd1},{5'd5,6'd7,5'd2},{5'd5,6'd6,5'd1},{5'd4,6'd5,5'd1},{5'd5,6'd7,5'd2},{5'd4,6'd6,5'd1},{5'd4,6'd7,5'd1},
                            {5'd6,6'd7,5'd0},{5'd6,6'd7,5'd1},{5'd6,6'd7,5'd1},{5'd7,6'd9,5'd2},{5'd7,6'd10,5'd3},{5'd7,6'd10,5'd3},{5'd5,6'd7,5'd1},{5'd5,6'd7,5'd0},
                            {5'd7,6'd6,5'd0},{5'd21,6'd34,5'd13},{5'd23,6'd37,5'd15},{5'd23,6'd37,5'd16},{5'd22,6'd36,5'd15},{5'd22,6'd36,5'd15},{5'd19,6'd31,5'd12},{5'd8,6'd8,5'd0},
                            {5'd21,6'd32,5'd13},{5'd22,6'd34,5'd13},{5'd20,6'd31,5'd12},{5'd21,6'd31,5'd13},{5'd19,6'd28,5'd12},{5'd22,6'd35,5'd15},{5'd18,6'd27,5'd10},{5'd18,6'd26,5'd10},
                            {5'd21,6'd31,5'd14},{5'd31,6'd60,5'd29},{5'd13,6'd15,5'd7},{5'd21,6'd31,5'd15},{5'd22,6'd34,5'd16},{5'd13,6'd15,5'd6},{5'd31,6'd60,5'd28},{5'd21,6'd31,5'd13},
                            {5'd18,6'd25,5'd11},{5'd20,6'd30,5'd14},{5'd23,6'd34,5'd16},{5'd13,6'd14,5'd7},{5'd13,6'd14,5'd6},{5'd22,6'd34,5'd16},{5'd19,6'd27,5'd12},{5'd15,6'd20,5'd8},
                            {5'd17,6'd23,5'd8},{5'd17,6'd24,5'd9},{5'd14,6'd16,5'd5},{5'd14,6'd18,5'd6},{5'd14,6'd17,5'd6},{5'd13,6'd16,5'd5},{5'd17,6'd24,5'd8},{5'd15,6'd20,5'd7},
                            {5'd14,6'd17,5'd4},{5'd14,6'd17,5'd4},{5'd16,6'd21,5'd6},{5'd15,6'd20,5'd6},{5'd15,6'd19,5'd6},{5'd16,6'd21,5'd7},{5'd16,6'd21,5'd7},{5'd15,6'd19,5'd5}};
            MOTHCOBBLESTONE: COLOR = {{5'd20,6'd40,5'd20},{5'd20,6'd40,5'd20},{5'd20,6'd40,5'd20},{5'd8,6'd24,5'd8},{5'd12,6'd24,5'd16},{5'd20,6'd40,5'd20},{5'd16,6'd32,5'd16},{5'd24,6'd48,5'd24},
                            {5'd8,6'd24,5'd8},{5'd16,6'd32,5'd16},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},{5'd8,6'd16,5'd8},{5'd16,6'd32,5'd16},{5'd8,6'd16,5'd8},{5'd8,6'd24,5'd8},
                            {5'd20,6'd40,5'd20},{5'd12,6'd24,5'd16},{5'd20,6'd40,5'd20},{5'd16,6'd32,5'd16},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},
                            {5'd16,6'd32,5'd16},{5'd8,6'd32,5'd8},{5'd8,6'd24,5'd8},{5'd12,6'd24,5'd8},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},{5'd16,6'd32,5'd16},{5'd8,6'd32,5'd8},
                            {5'd16,6'd32,5'd16},{5'd8,6'd24,5'd8},{5'd8,6'd40,5'd8},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},{5'd8,6'd24,5'd8},{5'd8,6'd24,5'd8},{5'd24,6'd48,5'd24},
                            {5'd12,6'd24,5'd16},{5'd16,6'd32,5'd16},{5'd16,6'd32,5'd16},{5'd20,6'd40,5'd20},{5'd16,6'd32,5'd16},{5'd16,6'd32,5'd16},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},
                            {5'd20,6'd40,5'd20},{5'd8,6'd16,5'd8},{5'd8,6'd16,5'd8},{5'd8,6'd24,5'd8},{5'd8,6'd24,5'd8},{5'd20,6'd40,5'd20},{5'd8,6'd32,5'd8},{5'd8,6'd24,5'd8},
                            {5'd16,6'd32,5'd16},{5'd8,6'd24,5'd8},{5'd16,6'd32,5'd16},{5'd16,6'd32,5'd16},{5'd8,6'd24,5'd8},{5'd16,6'd32,5'd16},{5'd16,6'd32,5'd16},{5'd12,6'd24,5'd8}};
            default: COLOR ={{5'd5,6'd7,5'd1},{5'd5,6'd7,5'd1},{5'd5,6'd7,5'd2},{5'd5,6'd6,5'd1},{5'd4,6'd5,5'd1},{5'd5,6'd7,5'd2},{5'd4,6'd6,5'd1},{5'd4,6'd7,5'd1},
                            {5'd6,6'd7,5'd0},{5'd6,6'd7,5'd1},{5'd6,6'd7,5'd1},{5'd7,6'd9,5'd2},{5'd7,6'd10,5'd3},{5'd7,6'd10,5'd3},{5'd5,6'd7,5'd1},{5'd5,6'd7,5'd0},
                            {5'd7,6'd6,5'd0},{5'd21,6'd34,5'd13},{5'd23,6'd37,5'd15},{5'd23,6'd37,5'd16},{5'd22,6'd36,5'd15},{5'd22,6'd36,5'd15},{5'd19,6'd31,5'd12},{5'd8,6'd8,5'd0},
                            {5'd21,6'd32,5'd13},{5'd22,6'd34,5'd13},{5'd20,6'd31,5'd12},{5'd21,6'd31,5'd13},{5'd19,6'd28,5'd12},{5'd22,6'd35,5'd15},{5'd18,6'd27,5'd10},{5'd18,6'd26,5'd10},
                            {5'd21,6'd31,5'd14},{5'd31,6'd60,5'd29},{5'd13,6'd15,5'd7},{5'd21,6'd31,5'd15},{5'd22,6'd34,5'd16},{5'd13,6'd15,5'd6},{5'd31,6'd60,5'd28},{5'd21,6'd31,5'd13},
                            {5'd18,6'd25,5'd11},{5'd20,6'd30,5'd14},{5'd23,6'd34,5'd16},{5'd13,6'd14,5'd7},{5'd13,6'd14,5'd6},{5'd22,6'd34,5'd16},{5'd19,6'd27,5'd12},{5'd15,6'd20,5'd8},
                            {5'd17,6'd23,5'd8},{5'd17,6'd24,5'd9},{5'd14,6'd16,5'd5},{5'd14,6'd18,5'd6},{5'd14,6'd17,5'd6},{5'd13,6'd16,5'd5},{5'd17,6'd24,5'd8},{5'd15,6'd20,5'd7},
                            {5'd14,6'd17,5'd4},{5'd14,6'd17,5'd4},{5'd16,6'd21,5'd6},{5'd15,6'd20,5'd6},{5'd15,6'd19,5'd6},{5'd16,6'd21,5'd7},{5'd16,6'd21,5'd7},{5'd15,6'd19,5'd5}};
        endcase
    end
endmodule

module AudioVisualizationSceneBuilder #(parameter scenesize = 34) (input CLK, input Reflush, input [6:0] Qstart, input [1:0] THEME, input THK, input BD, input BG, input BAR, input TXT, input [3:0] LEVEL, output [63:0] CMD, output [6:0] CNT);
    reg [63:0] AudioBar [scenesize - 1:0];//34 commands
    reg [6:0] count = 0 - 1;
    reg [63:0] cmd = 64'd0;
    reg [15:0] BGT [2:0] = {{5'd0,6'd0,5'd0},{5'd31,6'd63,5'd31},{5'd0,6'd0,5'd31}};// black, white, blue
    reg [15:0] BT [2:0] = {{5'd31,6'd63,5'd31},{5'd0,6'd31,5'd0},{5'd31,6'd32,5'd0}};// white, dark green, orange
    reg [15:0] HT [2:0] = {{5'd31,6'd0,5'd0},{5'd0,6'd0,5'd31},{5'd31,6'd63,5'd0}};// red, blue, yellow
    reg [15:0] MT [2:0] = {{5'd31,6'd63,5'd0},{5'd0,6'd0,5'd15},{5'd0,6'd63,5'd0}};// yellow, dark blue, green
    reg [15:0] LT [2:0] = {{5'd0,6'd63,5'd0},{5'd0,6'd0,5'd0},{5'd31,6'd0,5'd31}};// green, black, magenta
    `include "CommandFunctions.v"
    assign AudioBar[0] = BG ? FillRect(7'd0, 6'd0, 7'd95, 6'd63, BGT[THEME]) : IdleCmd();//Fill Background
    assign AudioBar[1] = BD ? DrawRect(7'd0, 6'd0, 7'd95, 6'd63, BT[THEME]) : IdleCmd();// drawboarder outermost 1 pix at THK 1
    assign AudioBar[2] = BD & THK ? DrawRect(7'd1, 6'd1, 7'd94, 6'd62, BT[THEME]) : IdleCmd();// drawboarder outermost 2 pix at THK 1
    assign AudioBar[3] = BD & THK ? DrawRect(7'd2, 6'd2, 7'd93, 6'd61, BT[THEME]) : IdleCmd();// drawboarder outermost 3 pix at THK 1
    assign AudioBar[4] = BAR ? FillRect(7'd42, 6'd58, 7'd53, 6'd59, LT[THEME]) : IdleCmd();//Fill BtmLevel1
    assign AudioBar[5] = BAR & (LEVEL > 4'd0) ? FillRect(7'd42, 6'd55, 7'd53, 6'd56, LT[THEME]) : IdleCmd();//Fill BtmLevel2
    assign AudioBar[6] = BAR & (LEVEL > 4'd1) ? FillRect(7'd42, 6'd52, 7'd53, 6'd53, LT[THEME]) : IdleCmd();//Fill BtmLevel3
    assign AudioBar[7] = BAR & (LEVEL > 4'd2) ? FillRect(7'd42, 6'd49, 7'd53, 6'd50, LT[THEME]) : IdleCmd();//Fill BtmLevel4
    assign AudioBar[8] = BAR & (LEVEL > 4'd3) ? FillRect(7'd42, 6'd46, 7'd53, 6'd47, LT[THEME]) : IdleCmd();//Fill BtmLevel5
    assign AudioBar[9] = BAR & (LEVEL > 4'd4) ? FillRect(7'd42, 6'd43, 7'd53, 6'd44, LT[THEME]) : IdleCmd();//Fill MidLevel6
    assign AudioBar[10] = BAR & (LEVEL > 4'd5) ? FillRect(7'd42, 6'd40, 7'd53, 6'd41, MT[THEME]) : IdleCmd();//Fill MidLevel1
    assign AudioBar[11] = BAR & (LEVEL > 4'd6) ? FillRect(7'd42, 6'd37, 7'd53, 6'd38, MT[THEME]) : IdleCmd();//Fill MidLevel2
    assign AudioBar[12] = BAR & (LEVEL > 4'd7) ? FillRect(7'd42, 6'd34, 7'd53, 6'd35, MT[THEME]) : IdleCmd();//Fill MidLevel3
    assign AudioBar[13] = BAR & (LEVEL > 4'd8) ? FillRect(7'd42, 6'd31, 7'd53, 6'd32, MT[THEME]) : IdleCmd();//Fill MidLevel4
    assign AudioBar[14] = BAR & (LEVEL > 4'd9) ? FillRect(7'd42, 6'd28, 7'd53, 6'd29, MT[THEME]) : IdleCmd();//Fill MidLevel5
    assign AudioBar[15] = BAR & (LEVEL > 4'd10) ? FillRect(7'd42, 6'd25, 7'd53, 6'd26, HT[THEME]) : IdleCmd();//Fill TopLevel1
    assign AudioBar[16] = BAR & (LEVEL > 4'd11) ? FillRect(7'd42, 6'd22, 7'd53, 6'd23, HT[THEME]) : IdleCmd();//Fill TopLevel2
    assign AudioBar[17] = BAR & (LEVEL > 4'd12) ? FillRect(7'd42, 6'd19, 7'd53, 6'd20, HT[THEME]) : IdleCmd();//Fill TopLevel3
    assign AudioBar[18] = BAR & (LEVEL > 4'd13) ? FillRect(7'd42, 6'd16, 7'd53, 6'd17, HT[THEME]) : IdleCmd();//Fill TopLevel4
    assign AudioBar[19] = BAR & (LEVEL > 4'd14) ? FillRect(7'd42, 6'd13, 7'd53, 6'd14, HT[THEME]) : IdleCmd();//Fill TopLevel5    
    assign AudioBar[20] = TXT ? DrawChar(7'd55, 6'd53, 20'd11, LT[THEME], 1'd0) : IdleCmd(); //L, original size
    assign AudioBar[21] = TXT ? DrawChar(7'd60, 6'd53, 20'd14, LT[THEME], 1'd0) : IdleCmd(); //O, original size
    assign AudioBar[22] = TXT ? DrawChar(7'd65, 6'd53, 20'd22, LT[THEME], 1'd0) : IdleCmd(); //W, original size
    assign AudioBar[23] = TXT ? DrawChar(7'd75, 6'd53, 20'd21, LT[THEME], 1'd0) : IdleCmd(); //V, original size
    assign AudioBar[24] = TXT ? DrawChar(7'd80, 6'd53, 20'd14, LT[THEME], 1'd0) : IdleCmd(); //O, original size
    assign AudioBar[25] = TXT ? DrawChar(7'd85, 6'd53, 20'd11, LT[THEME], 1'd0) : IdleCmd(); //L, original size
    assign AudioBar[26] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd55, 6'd13, 20'd7, HT[THEME], 1'd0) : IdleCmd(); //H, original size
    assign AudioBar[27] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd60, 6'd13, 20'd8, HT[THEME], 1'd0) : IdleCmd(); //I, original size
    assign AudioBar[28] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd65, 6'd13, 20'd6, HT[THEME], 1'd0) : IdleCmd(); //G, original size
    assign AudioBar[29] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd70, 6'd13, 20'd7, HT[THEME], 1'd0) : IdleCmd(); //H, original size
    assign AudioBar[30] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd75, 6'd13, 20'd21, HT[THEME], 1'd0) : IdleCmd(); //V, original size
    assign AudioBar[31] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd80, 6'd13, 20'd14, HT[THEME], 1'd0) : IdleCmd(); //O, original size
    assign AudioBar[32] = TXT & (LEVEL > 4'd10) ? DrawChar(7'd85, 6'd13, 20'd11, HT[THEME], 1'd0) : IdleCmd(); //L, original size
    assign AudioBar[33] = JMP(Qstart);//Jump to Qstart;
    always @(posedge CLK) begin
        if (Reflush) count = 0;
        if (count == scenesize) count = 0;
        else count = count + 1;
        cmd = AudioBar[count];
    end
    assign CMD = cmd;
    assign CNT = count;
endmodule

module StartScreenSceneBuilder #(parameter scenesize = 15) (input CLK, input [1:0] CURSORINDEX, output [63:0] CMD, output [6:0] CNT);
    reg [63:0] StartScreen [scenesize - 1:0];//15 commands
    reg [4:0] count = 0 - 1;
    reg [63:0] cmd = 64'd0;
    reg [15:0] WHITE = {5'd31,6'd63,5'd31};
    reg [15:0] AQUA = {5'd10, 6'd40, 5'd31};
    `include "CommandFunctions.v"
    assign StartScreen[0] = QuickDrawSceneSprite(7'd0, 6'd0, WHITE, 3'd1, 2'd2 );//brick wall (0,0), quadriple size
    assign StartScreen[1] = QuickDrawSceneSprite(7'd4, 6'd0, WHITE, 3'd1, 2'd2 );//brick wall (1,0), quadriple size
    assign StartScreen[2] = QuickDrawSceneSprite(7'd8, 6'd0, WHITE, 3'd1, 2'd2 );//brick wall (2,0), quadriple size
    assign StartScreen[3] = QuickDrawSceneSprite(7'd0, 6'd4, WHITE, 3'd0, 2'd2 );//grass block (0,1), quadriple size
    assign StartScreen[4] = QuickDrawSceneSprite(7'd4, 6'd4, WHITE, 3'd0, 2'd2 );//grass block (1,1), quadriple size
    assign StartScreen[5] = QuickDrawSceneSprite(7'd8, 6'd4, WHITE, 3'd0, 2'd2 );//grass block (2,1), quadriple size
    assign StartScreen[6] = DrawRect(7'd6, 6'd22, 7'd89, 6'd41, WHITE);//Draw Chr boarderline white
    assign StartScreen[7] = DrawChar(7'd10, 6'd25, 20'd22, AQUA,1'd1); //W, double size
    assign StartScreen[8] = DrawChar(7'd21, 6'd25, 20'd4, AQUA,1'd1); //E, double size
    assign StartScreen[9] = DrawChar(7'd32, 6'd25, 20'd11, AQUA,1'd1); //L, double size
    assign StartScreen[10] = DrawChar(7'd43, 6'd25, 20'd2, AQUA,1'd1); //C, double size
    assign StartScreen[11] = DrawChar(7'd54, 6'd25, 20'd14, AQUA,1'd1); //O, double size
    assign StartScreen[12] = DrawChar(7'd65, 6'd25, 20'd12, AQUA,1'd1); //M, double size
    assign StartScreen[13] = DrawChar(7'd76, 6'd25, 20'd4, AQUA,1'd1); //E, double size
    assign StartScreen[14] = DBNCH(7'd14, 7'd15, 2'b0);//JMP to 14 if imme is in startscreen mode
    always @(posedge CLK) begin
        if (count == scenesize) count = 0;
        else count = count + 1;
        cmd = StartScreen[count];
    end
    assign CMD = cmd;
    assign CNT = count;
endmodule


module MazeSceneBuilder #(parameter scenesize = 15) (input CLK, input [1:0] MazeDState, output CMD);
    reg [63:0] MazeScene [31:0];//32 commands
    reg [5:0] count = 0;
    reg [63:0] cmd;
    reg [15:0] RED = {5'd31,6'd0,5'd0};
    reg [15:0] WHITE = {5'd31,6'd63,5'd31};
    `include "CommandFunctions.v"
    
    //Background - MothCobblestone
    assign MazeScene[0] = QuickDrawSceneSprite(7'd0, 6'd0, WHITE, 3'd4, 2'd2 );//MothCobblestone (0,0), quadriple size
    assign MazeScene[1] = QuickDrawSceneSprite(7'd4, 6'd0, WHITE, 3'd4, 2'd2 );//MothCobblestone (1,0), quadriple size
    assign MazeScene[2] = QuickDrawSceneSprite(7'd8, 6'd0, WHITE, 3'd4, 2'd2 );//MothCobblestone (2,0), quadriple size
    assign MazeScene[3] = QuickDrawSceneSprite(7'd0, 6'd4, WHITE, 3'd4, 2'd2 );//MothCobblestone (0,1), quadriple size
    assign MazeScene[4] = QuickDrawSceneSprite(7'd4, 6'd4, WHITE, 3'd4, 2'd2 );//MothCobblestone (1,1), quadriple size
    assign MazeScene[5] = QuickDrawSceneSprite(7'd8, 6'd4, WHITE, 3'd4, 2'd2 );//MothCobblestone (2,1), quadriple size
    
    //GAME START             //x position   y    char  color  size
    assign MazeScene[6] = DrawChar(7'd10, 6'd20, 20'd6, RED ,1'd0); //G, original size
    assign MazeScene[7] = DrawChar(7'd15, 6'd20, 20'd0, RED ,1'd0); //A, original size
    assign MazeScene[8] = DrawChar(7'd20, 6'd20, 20'd12, RED ,1'd0); //M, original size
    assign MazeScene[9] = DrawChar(7'd25, 6'd20, 20'd4, RED ,1'd0); //E, original size
    assign MazeScene[10] = DrawChar(7'd30, 6'd20, 20'd19, RED ,1'd0); //S, original size
    assign MazeScene[11] = DrawChar(7'd35, 6'd20, 20'd20, RED ,1'd0); //T, original size
    assign MazeScene[12] = DrawChar(7'd40, 6'd20, 20'd0, RED ,1'd0); //A, original size
    assign MazeScene[13] = DrawChar(7'd45, 6'd20, 20'd18, RED ,1'd0); //R, original size
    assign MazeScene[14] = DrawChar(7'd45, 6'd20, 20'd20, RED ,1'd0); //T, original size
    
    //WIN
    assign MazeScene[15] = DrawChar(7'd10, 6'd20, 20'd22, RED ,1'd0); //W, original size
    assign MazeScene[16] = DrawChar(7'd20, 6'd20, 20'd8, RED ,1'd0); //I, original size
    assign MazeScene[17] = DrawChar(7'd30, 6'd20, 20'd13, RED ,1'd0); //N, original size
    
    //LOSE
    assign MazeScene[18] = DrawChar(7'd10, 6'd20, 20'd6, RED ,1'd0); //L, original size
    assign MazeScene[19] = DrawChar(7'd15, 6'd20, 20'd6, RED ,1'd0); //O, original size
    assign MazeScene[20] = DrawChar(7'd20, 6'd20, 20'd6, RED ,1'd0); //S, original size
    assign MazeScene[21] = DrawChar(7'd25, 6'd20, 20'd6, RED ,1'd0); //E, original size
    
    always @(posedge CLK) begin
        cmd = MazeScene[count];
        if((count == 6'd8) && (MazeDState==2'b01)) count = 6'd0; //GAME START
        if((count == 6'd11) && (MazeDState==2'b10)) count = 6'd8; //WIN
        if((count == 6'd15) && (MazeDState==2'b11)) count = 6'd11; //LOSE
        count = count + 6'd1;
    end
    assign CMD = cmd;
endmodule