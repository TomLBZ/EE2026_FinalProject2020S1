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

module GraphicsProcessingUnit(input [63:0] Command,input ON, input CLK, input [1:0] IMME, output [6:0] RADDR, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output DONE, output BUSY);//64-bit command
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
    localparam [3:0] SBNCH = 13;//cmd[0:6]RADDR,[7:8]CMP
    localparam [3:0] DBNCH = 14;//cmd[0:6]RADDR1,[7:13]RADDR2,[14:15]CMP
    localparam [3:0] JMP = 15;//cmd[0:6]RADDR;
    localparam [3:0] CommandUpperBound = 9;
    localparam [6:0] XupperBound = 96;
    reg [1:0] STATE; initial STATE = 2'd0;
    reg [6:0] raddr; initial raddr = 0 - 1;
    wire busy = STATE == STR;
    wire [15:0] B;//busy wires
    wire OnCommand = Command[63];
    wire [3:0] commandHead = Command[62:59];//read 4 bit head if OnCommand
    assign DONE = busy && OnCommand && B[commandHead] == 0;//if OnCommand, check if current command is no longer busy. else set 1
    wire [15:0] O;//on wires
    assign O[IDLE] = (commandHead == IDLE);
    assign O[PT] = OnCommand && (commandHead == PT);
    assign O[LN] = OnCommand && (commandHead == LN);
    assign O[CHR] = OnCommand && (commandHead == CHR);
    assign O[RECT] = OnCommand && (commandHead == RECT);
    assign O[CIRC] = OnCommand && (commandHead == CIRC);
    assign O[SPRSCN] = OnCommand && (commandHead == SPRSCN);
    assign O[FRECT] = OnCommand && (commandHead == FRECT);
    assign O[FCIRC] = OnCommand && (commandHead == FCIRC);
    assign O[9] = OnCommand && (commandHead == 9);
    assign O[10] = OnCommand && (commandHead == 10);
    assign O[11] = OnCommand && (commandHead == 11);
    assign O[12] = OnCommand && (commandHead == 12);
    assign O[SBNCH] = OnCommand && (commandHead == SBNCH);
    assign O[DBNCH] = OnCommand && (commandHead == DBNCH);
    assign O[JMP] = OnCommand && (commandHead == JMP);
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
    reg [6:0] XO; initial XO = 7'd0;
    reg [5:0] YO; initial YO = 6'd0;
    reg [15:0] CO; initial CO = 16'd0;
    wire [6:0] Xout[15:0];//Xouts
    wire [5:0] Yout[15:0];//Youts
    wire [15:0] Cout[15:0];//Couts
    OnIdleCommand OIC(CLK, O[IDLE], XO, YO, CO, Xout[IDLE], Yout[IDLE], Cout[IDLE], B[IDLE]);
    OnPointCommand OPC(CLK, O[PT], Command, Xout[PT], Yout[PT], Cout[PT], B[PT]);
    OnLineCommand OLNC(CLK, O[LN], Command, Xout[LN], Yout[LN], Cout[LN], B[LN]);
    OnCharCommand OCHRC(CLK, O[CHR], Command, Xout[CHR], Yout[CHR], Cout[CHR], B[CHR]);
    OnRectCommand ORECTC(CLK, O[RECT], Command, Xout[RECT], Yout[RECT], Cout[RECT], B[RECT]);
    OnCircleCommand OCIRCC(CLK, O[CIRC], Command, Xout[CIRC], Yout[CIRC], Cout[CIRC], B[CIRC]);
    OnSceneSpriteCommand OSPRSCNC(CLK, O[SPRSCN], Command, Xout[SPRSCN], Yout[SPRSCN], Cout[SPRSCN], B[SPRSCN]);
    OnFillRectCommand OFRECTC(CLK, O[FRECT], Command, Xout[FRECT], Yout[FRECT], Cout[FRECT], B[FRECT]);
    OnFillCircCommand OFCIRCC(CLK, O[FCIRC], Command, Xout[FCIRC], Yout[FCIRC], Cout[FCIRC], B[FCIRC]);  
    OnIdleCommand OIC9(CLK, O[9], XO, YO, CO, Xout[9], Yout[9], Cout[9], B[9]);
    OnIdleCommand OIC10(CLK, O[10], XO, YO, CO, Xout[10], Yout[10], Cout[10], B[10]);
    OnIdleCommand OIC11(CLK, O[11], XO, YO, CO, Xout[11], Yout[11], Cout[11], B[11]);
    OnIdleCommand OIC12(CLK, O[12], XO, YO, CO, Xout[12], Yout[12], Cout[12], B[12]);
    OnSingleBranchCommand OSBC(CLK, O[SBNCH], Command, IMME, raddr, Xout[SBNCH], Yout[SBNCH], Cout[SBNCH], B[SBNCH]);
    OnDoubleBranchCommand ODBC(CLK, O[DBNCH], Command, IMME, Xout[DBNCH], Yout[DBNCH], Cout[DBNCH], B[DBNCH]);
    OnJumpCommand OJC(CLK, O[JMP], Command, Xout[JMP], Yout[JMP], Cout[JMP], B[JMP]);    
    wire STPCLK = STATE == STP ? 1 : 0;
    always @ (*) begin
        if (busy) begin //state is str
            if(commandHead < CommandUpperBound) begin
                if (Xout[commandHead] < XupperBound) begin
                    XO = Xout[commandHead];
                    YO = Yout[commandHead];
                    CO = Cout[commandHead];
                end //else means idle
            end  
        end
    end
    always @ (posedge STPCLK) begin
        if (commandHead >= CommandUpperBound) begin //special commands
            case (commandHead)
                SBNCH:begin 
                    raddr = Xout[commandHead];
                end
                DBNCH:begin
                    raddr = Xout[commandHead];
                end
                JMP:begin
                    raddr = Xout[commandHead];
                end
                default:begin raddr = raddr + 1; end
            endcase
        end else raddr = raddr + 1;//normal commands
    end
    assign BUSY = busy;
    assign RADDR = raddr;
    assign X = XO;
    assign Y = YO;
    assign COLOR = CO;
endmodule