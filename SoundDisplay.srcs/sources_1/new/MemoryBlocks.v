`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/16/2020 08:58:28 AM
// Design Name: FGPA Project for EE2026
// Module Name: DisplayRAM, DisplayCommands, CharBlocks
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module provides data structures to store relatively large amount of data and interact with them.The screen and the user input are decoupled here.
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module DisplayRAM(input [12:0] readPix, input CLK, input Write, input [6:0] X, input [5:0] Y, input [15:0] COLOR, output [15:0] STREAM);
    reg [15:0] DRAM [6143:0];
    reg [15:0] stream;
    always @(readPix) begin
        stream = DRAM[readPix]; 
    end
    assign STREAM = stream;
    always @(posedge CLK) begin
        if (Write) begin
            DRAM[Y * 96 + X] = COLOR;
        end
    end
endmodule

module DisplayCommandCore(input [63:0] Command,input ON, input CLK, output PixelSet, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY, output Done);//64-bit command
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] END = 2;//end drawing
    reg [1:0] STATE;
    wire busy = STATE == STR;
    wire PTBUSY;
    wire LNBUSY;
    wire CHRBUSY;
    wire RECTBUSY;
    wire CIRCBUSY;
    wire FRECTBUSY;
    wire FCIRCBUSY;
    wire CMDBUSY = PTBUSY || LNBUSY || CHRBUSY || RECTBUSY || CIRCBUSY || FRECTBUSY || FCIRCBUSY;//initially is zero
    wire [63:0] cmd = CMDBUSY ? cmd : Command;
    wire OnCommand = cmd[63];//enabling signal
    wire DONE = !CMDBUSY;//if everything not busy then done
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
    wire [3:0] commandHead = cmd[62:59];//4 bit head
    reg [6:0] XO;
    reg [5:0] YO;
    reg [15:0] CO;
    localparam [3:0] IDLE = 0;//cmd[63]=1, rest empty
    localparam [3:0] PT = 1;//cmd[0:6]X,[7:12]Y,[13:28]C
    localparam [3:0] LN = 2;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    localparam [3:0] CHR = 3;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:58]CHR//30-bit char set{[29:54]AZ,[55:58]", . [ ]"}
    localparam [3:0] RECT = 4;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    localparam [3:0] CIRC = 5;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    localparam [3:0] SPR = 6;//cmd[0:6]X1,[7:12]Y1,[14:13]MODE,[19:15]INDEX
    localparam [3:0] FRECT = 7;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    localparam [3:0] FCIRC = 8;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    wire onPT = busy && OnCommand && (commandHead == PT);
    wire [6:0] PTXout;
    wire [5:0] PTYout;
    wire [15:0] PTCout;
    OnPointCommand OPC(CLK, onPT, cmd, PTXout, PTYout, PTCout, PTBUSY);
    wire onLN = busy && OnCommand && (commandHead == LN);
    wire [6:0] LNXout;
    wire [5:0] LNYout;
    wire [15:0] LNCout;
    OnLineCommand OLNC(CLK, onLN, cmd, LNXout, LNYout, LNCout, LNBUSY);
    wire onCHR = busy && OnCommand && (commandHead == CHR);
    wire [6:0] CHRXout;
    wire [5:0] CHRYout;
    wire [15:0] CHRCout;
    OnCharCommand OCHRC(CLK, onCHR, cmd, CHRXout, CHRYout, CHRCout, CHRBUSY);
    wire onRECT = busy && OnCommand && (commandHead == RECT);
    wire [6:0] RECTXout;
    wire [5:0] RECTYout;
    wire [15:0] RECTCout;
    OnRectCommand ORECTC(CLK, onRECT, cmd, RECTXout, RECTYout, RECTCout, RECTBUSY);
    wire onCIRC = busy && OnCommand && (commandHead == CIRC);
    wire [6:0] CIRCXout;
    wire [5:0] CIRCYout;
    wire [15:0] CIRCCout;
    OnCircleCommand OCIRCC(CLK, onCIRC, cmd, CIRCXout, CIRCYout, CIRCCout, CIRCBUSY);
    wire onFRECT = busy && OnCommand && (commandHead == FRECT);
    wire [6:0] FRECTXout;
    wire [5:0] FRECTYout;
    wire [15:0] FRECTCout;
    OnFillRectCommand OFRECTC(CLK, onFRECT, cmd, FRECTXout, FRECTYout, FRECTCout, FRECTBUSY);
    wire onFCIRC = busy && OnCommand && (commandHead == FCIRC);
    wire [6:0] FCIRCXout;
    wire [5:0] FCIRCYout;
    wire [15:0] FCIRCCout;
    OnFillCircCommand OFCIRCC(CLK, onFCIRC, cmd, FCIRCXout, FCIRCYout, FCIRCCout, FCIRCBUSY);
    always @ (*) begin
        if (busy && OnCommand) begin
            case (commandHead)
                IDLE:begin //move to bad point
                    XO = 0;
                    YO = 0;
                    CO = {5'd0,6'd0,5'd0};
                end
                PT:begin 
                    XO = PTXout;
                    YO = PTYout;
                    CO = PTCout;
                end
                LN:begin 
                    XO = LNXout;
                    YO = LNYout;
                    CO = LNCout;
                end
                CHR:begin 
                    XO = CHRXout;
                    YO = CHRYout;
                    CO = CHRCout;
                end
                RECT:begin 
                    XO = RECTXout;
                    YO = RECTYout;
                    CO = RECTCout;
                end
                CIRC:begin 
                    XO = CIRCXout;
                    YO = CIRCYout;
                    CO = CIRCCout;
                end
                SPR:begin 
                end
                FRECT:begin 
                    XO = FRECTXout;
                    YO = FRECTYout;
                    CO = FRECTCout;
                end
                FCIRC:begin
                    XO = FCIRCXout;
                    YO = FCIRCYout;
                    CO = FCIRCCout;
                end
                default:begin //assume idle, move to bad point
                    XO = 0;
                    YO = 0;
                    CO = {5'd0,6'd0,5'd0};
                end
            endcase
        end
    end
    assign BUSY = busy;
    assign PixelSet = CMDBUSY;
    assign X = XO;
    assign Y = YO;
    assign COLOR = CO;
    assign Done = DONE;
endmodule

module CharBlocks(input [29:0] CHR, output [34:0] MAP);
    reg [34:0] map;
    always @ (*) begin
        case (CHR)
            0:begin map = 35'b00100_01010_10001_11111_10001_10001_10001; end//A
            1:begin map = 35'b11110_10001_10001_11110_10001_10001_11110; end//B
            2:begin map = 35'b01110_10001_10000_10000_10000_10001_01110; end//C
            3:begin map = 35'b11100_10010_10001_10001_10001_10010_11100; end//D
            4:begin map = 35'b11111_10000_10000_11110_10000_10000_11111; end//E
            5:begin map = 35'b11111_10000_10000_11110_10000_10000_10000; end//F
            6:begin map = 35'b01110_10001_10000_10011_10001_10001_01110; end//G
            7:begin map = 35'b10001_10001_10001_11111_10001_10001_10001; end//H
            8:begin map = 35'b01110_00100_00100_00100_00100_00100_01110; end//I
            9:begin map = 35'b01110_00100_00100_00100_10100_10100_01100; end//J
            10:begin map = 35'b10001_10010_10100_11000_10100_10010_10001; end//K
            11:begin map = 35'b10000_10000_10000_10000_10000_10000_11111; end//L
            12:begin map = 35'b01010_01010_10101_10101_10101_10001_10001; end//M
            13:begin map = 35'b10001_11001_11001_10101_10011_10011_10001; end//N
            14:begin map = 35'b01110_10001_10001_10001_10001_10001_01110; end//O
            15:begin map = 35'b11111_10001_10001_11111_10000_10000_10000; end//P
            16:begin map = 35'b01100_10010_10010_10010_10010_10110_01111; end//Q
            17:begin map = 35'b11111_10001_10001_11110_10100_10010_10001; end//R
            08:begin map = 35'b01110_10001_10000_01110_00001_10001_01110; end//S
            19:begin map = 35'b11111_00100_00100_00100_00100_00100_00100; end//T
            20:begin map = 35'b10001_10001_10001_10001_10001_10001_01110; end//U
            21:begin map = 35'b10001_10001_10001_10001_10001_01010_00100; end//V
            22:begin map = 35'b10001_10001_10101_10101_10101_01010_01010; end//W
            23:begin map = 35'b10001_10001_01010_00100_01010_10001_10001; end//X
            24:begin map = 35'b10001_10001_01010_00100_00100_00100_00100; end//Y
            25:begin map = 35'b11111_00001_00010_00100_01000_10000_11111; end//Z
            26:begin map = 35'b00000_00000_00000_00000_01100_00100_01000; end//,
            27:begin map = 35'b00000_00000_00000_00000_00000_01100_01100; end//.
            28:begin map = 35'b00110_00100_00100_00100_00100_00100_00110; end//[
            29:begin map = 35'b01100_00100_00100_00100_00100_00100_01100; end//]
            default: begin map = 35'b0; end//Nothing
        endcase
    end
    assign MAP = map;
endmodule

module SceneSpriteBlocks(input [29:0] SCN, output reg [15:0] COLOR[255:0]);
    localparam [1:0] BRICK = 0;
    localparam [1:0] GRASS = 1;    
    localparam [1:0] CACTUS = 2;
    localparam [15:0] Br[8:0]={{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0}};//Brown
    localparam [15:0] Gr[8:0]={{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0},{5'd0,6'd0,5'd0}};//Green
    always @(*) begin
        case (SCN)
            BRICK: COLOR = {Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0]};
            GRASS: COLOR = {Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0]};
            CACTUS: COLOR ={Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],
                            Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0],Br[0]};
            default: begin COLOR = {0}; end
        endcase
    end
endmodule