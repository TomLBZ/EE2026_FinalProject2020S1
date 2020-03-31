`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2020 07:37:10 PM
// Design Name: 
// Module Name: GraphicsProcessingUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module GraphicsProcessingUnit(input [63:0] Command,input ON, input CLK, output [6:0] RADDR, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);//64-bit command
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    localparam [3:0] IDLE = 0;//cmd[63]=1, rest empty
    localparam [3:0] PT = 1;//cmd[0:6]X,[7:12]Y,[13:28]C
    localparam [3:0] LN = 2;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    localparam [3:0] CHR = 3;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:58]CHR//30-bit char set{[29:54]AZ,[55:58]", . [ ]"}
    localparam [3:0] RECT = 4;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    localparam [3:0] CIRC = 5;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    localparam [3:0] SPRSCN = 6;//cmd[0:6]X1,[7:12]Y1,[13:28]MCOLOR,[29:35]INDEX,[36:37]POWER
    localparam [3:0] FRECT = 7;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    localparam [3:0] FCIRC = 8;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    localparam [3:0] JMP = 15;//cmd[0:6]RADDR;
    reg [1:0] STATE;
    wire busy = STATE == STR;
    wire [15:0] B;//busy wires
    wire OnCommand = Command[63];//enabling signal
    wire [3:0] commandHead = Command[62:59];//4 bit head
    wire DONE = !B[commandHead];//if current command is no longer busy then done
    wire [15:0] O;//on wires
    assign O[PT] = busy && OnCommand && (commandHead == PT);
    assign O[LN] = busy && OnCommand && (commandHead == LN);
    assign O[CHR] = busy && OnCommand && (commandHead == CHR);
    assign O[RECT] = busy && OnCommand && (commandHead == RECT);
    assign O[CIRC] = busy && OnCommand && (commandHead == CIRC);
    assign O[SPRSCN] = busy && OnCommand && (commandHead == SPRSCN);
    assign O[FRECT] = busy && OnCommand && (commandHead == FRECT);
    assign O[FCIRC] = busy && OnCommand && (commandHead == FCIRC);
    always @ (posedge CLK) begin//change state
        case (STATE)
            IDL: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            STR: begin
                if (DONE) STATE <= STP;//if done then stop
                else STATE <= STR;//else start
            end
            STP: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            default: STATE <= IDL;//default idle
        endcase
    end
    reg [6:0] XO;
    reg [5:0] YO;
    reg [15:0] CO;
    wire [6:0] Xout[15:0];//Xouts
    wire [5:0] Yout[15:0];//Youts
    wire [15:0] Cout[15:0];//Couts
    assign Xout[0] = 0;//idle
    assign Yout[0] = 0;//idle
    assign Cout[0] = 0;//idle
    OnPointCommand OPC(CLK, O[PT], Command, Xout[PT], Yout[PT], Cout[PT], B[PT]);
    OnLineCommand OLNC(CLK, O[LN], Command, Xout[LN], Yout[LN], Cout[LN], B[LN]);
    OnCharCommand OCHRC(CLK, O[CHR], Command, Xout[CHR], Yout[CHR], Cout[CHR], B[CHR]);
    OnRectCommand ORECTC(CLK, O[RECT], Command, Xout[RECT], Yout[RECT], Cout[RECT], B[RECT]);
    OnCircleCommand OCIRCC(CLK, O[CIRC], Command, Xout[CIRC], Yout[CIRC], Cout[CIRC], B[CIRC]);
    OnSceneSpriteCommand OSPRSCNC(CLK, O[SPRSCN], Command, Xout[SPRSCN], Yout[SPRSCN], Cout[SPRSCN], B[SPRSCN]);
    OnFillRectCommand OFRECTC(CLK, O[FRECT], Command, Xout[FRECT], Yout[FRECT], Cout[FRECT], B[FRECT]);
    OnFillCircCommand OFCIRCC(CLK, O[FCIRC], Command, Xout[FCIRC], Yout[FCIRC], Cout[FCIRC], B[FCIRC]);  
    always @ (*) begin
        if (busy && OnCommand) begin
            XO = Xout[commandHead];
            YO = Yout[commandHead];
            CO = Cout[commandHead];
        end
    end
    reg [6:0] raddr = 0;
    always @ (posedge CLK) begin
        if (commandHead == JMP) raddr = Command[6:0];
        else raddr = raddr + 1;
    end
    assign RADDR = raddr;
    assign BUSY = busy;
    assign X = XO;
    assign Y = YO;
    assign COLOR = CO;
endmodule