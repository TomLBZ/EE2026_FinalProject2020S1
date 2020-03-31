`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// Create Date: 03/13/2020 09:51:11 AM
// Design Name: FGPA Project for EE2026
// Module Name: OnPointCommand, OnLineCommand, OnCharCommand, OnRectCommand, OnCircCommand, OnSceneSpriteCommand, OnFillRectCommand, OnFillCircCommand, 
//              Graphics
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module can be used to draw geometric shapes and texts conveniently.
// Dependencies: MemoryBlocks.v, CommandFunctions.v, Peripherals.v
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module OnPointCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] pX = CMD[6:0];
    wire [5:0] pY = CMD[12:7];
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    reg drawn = 0;
    wire DONE = drawn;
    wire busy = (STATE == STR);
    reg [6:0] x;
    reg [5:0] y;
    always @ (posedge CLK) begin
        if (busy) begin
            x <= pX;
            y <= pY;        
            drawn <= drawn + 1;
        end
    end
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
    assign BUSY = busy;
    assign X = x;
    assign Y = y;
endmodule

module OnLineCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] X1 = CMD[6:0];
    wire [5:0] Y1 = CMD[12:7];
    wire [6:0] X2 = CMD[35:29];
    wire [5:0] Y2 = CMD[41:36];
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    reg signed [8:0] e;//error
    reg signed [7:0] x;//x
    reg signed [6:0] y;//y
    reg [6:0] XO;//x output
    reg [5:0] YO;//y output
    wire loop = (STATE == STR);//if started, then loops
    wire signed [7:0] dX = X2 - X1;//signed, msb is the sign, actually is [6:0] X data.
    wire signed [7:0] rSignX = ~(dX[7]);//reverse sign of dX. if dX was positive, this would return 1.
    wire signed [7:0] DX = (!rSignX) ? -dX : dX;//if dX was positive, DX = dX. else DX = -dX. -> always positive
    wire signed [6:0] dY = Y2 - Y1;//signed, msb is the sign, actually is [5:0] Y data.
    wire signed [6:0] rSignY = ~(dY[6]);//reverse sign of dY. if dY was positive, this would return 1.
    wire signed [6:0] DY = rSignY ? -dY : dY;//if dY was positive, DY = -dY. else DY = dY. -> always negative
    wire signed [8:0] e2 = e << 1;//left shift, equivalent to times 2.
    wire e2bDY = (e2 > DY) ? 1 : 0;//is 2e bigger than DY?
    wire e2sDX = (e2 < DX) ? 1 : 0;//is 2e smaller than DX?
    wire signed [8:0] ei = e2bDY ? (e + DY) : e;//next e
    wire signed [8:0] eii = e2sDX ? (ei + DX) : e;//next next e
    wire signed [8:0] E = loop ? eii : (DX + DY);//get next correct value of e
    wire signed [7:0] XA = rSignX ? (x + 1) : (x - 1);//if dX positive, XA = x increments, else decrements
    wire signed [7:0] XB = e2bDY ? XA : x;//if 2e bigger than DY (eg. ini, DY < 0) then XB = XA. else x.
    wire signed [7:0] NX = loop ? XB: X1;//next x is XB unless not in loop
    wire signed [6:0] YA = rSignY ? (y + 1) : (y - 1);//if dY positive, YA = y increments, else decrements.
    wire signed [6:0] YB = e2sDX ? YA : y;//if 2e smaller than DX (eg. ini, DX > 0) then YB = YA. else y.
    wire signed [6:0] NY = loop ? YB : Y1;//next y is YB unless not in loop
    wire DONE = (XO == X2) && (YO == Y2);//reached end point
    always @ (posedge CLK) begin//update variable registers
        e <= E;
        x <= NX;
        y <= NY;
        if (loop) begin
            XO <= x[6:0];
            YO <= y[5:0];
        end
    end
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
    assign BUSY = loop;//if looping then busy
    assign X = XO;//without the sign
    assign Y = YO;//without the sign
endmodule

module OnCharCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] LX = CMD[6:0];
    wire [5:0] TY = CMD[12:7];
    wire [19:0] CHR = CMD[48:29];
    wire [1:0] POWER = CMD[50:49];
    wire [34:0] MAP;
    wire [6:0] RX = LX + (4'd4 << POWER);
    wire [5:0] BY = TY + (4'd6 << POWER);
    CharBlocks CB(CHR, MAP);
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg [6:0] XO;
    reg [5:0] YO;
    reg [6:0] xcount;
    reg [5:0] ycount;
    wire [2:0] chrX = (xcount - LX) >> POWER;
    wire [2:0] chrY = (ycount - TY) >> POWER;
    wire [5:0] index = 6'd34 - chrX - chrY * 3'd5;
    wire DONE = (xcount == RX && ycount == BY);//reached end point
    always @ (posedge CLK) begin // count x and y and update variables
        if (loop) begin
            if (MAP[index]==1'b1) begin
                XO <= xcount;
                YO <= ycount;
            end
            if (xcount == RX) begin
                xcount <= LX;
                if (ycount == BY) ycount <= TY;
                else ycount <= ycount + 1;
            end else xcount <= xcount + 1;
        end else begin
            xcount <= LX;
            ycount <= TY;
        end
    end
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
    assign BUSY = loop;
    assign X = XO;
    assign Y = YO;
endmodule

module OnRectCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] X1 = CMD[6:0];
    wire [5:0] Y1 = CMD[12:7];
    wire [6:0] X2 = CMD[35:29];
    wire [5:0] Y2 = CMD[41:36];
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg [6:0] XO;
    reg [5:0] YO;
    reg [6:0] xcount;
    reg [5:0] ycount;
    wire DONE = (xcount == X2 && ycount == Y2);//reached end point
    always @ (posedge CLK) begin // count x and y and update variables
        if (loop) begin
            XO <= xcount;
            YO <= ycount;
            if (xcount == X2) begin
                xcount <= X1;
                if (ycount == Y2) ycount <= Y1;
                else ycount <= ycount + 1;
            end else if (ycount > Y1 && ycount < Y2) begin
                xcount <= X2;
            end else xcount <= xcount + 1;
        end else begin
            xcount <= X1;
            ycount <= Y1;
        end
    end
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
    assign BUSY = loop;
    assign X = XO;
    assign Y = YO;
endmodule

module OnCircleCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] CX = CMD[6:0];
    wire [5:0] CY = CMD[12:7];
    wire [4:0] R = CMD[33:29];
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg signed [9:0] e;//error
    reg signed [7:0] x;//x
    reg signed [6:0] y;//y
    wire signed [5:0] r2 = R << 1;//2R
    wire signed [9:0] xx4 = x << 2;//4x
    wire signed [8:0] yx4 = y << 2;//4y
    wire eb0 = (e > 0) ? 1 : 0;//e bigger than 0
    wire signed [9:0] ei = eb0 ? e + xx4 - yx4 + 10 : e + xx4 + 6;
    wire signed [9:0] E = loop ? ei : 3 - r2;
    wire signed [6:0] dY = eb0 ? y - 1 : y;
    wire signed [7:0] NX = loop ? x + 1 : 0;
    wire signed [6:0] NY = loop ? dY : R;
    wire signed [7:0] xN [7:0];
    wire signed [6:0] yN [7:0];
    assign xN[0] = CX + x;//octadrant1
    assign yN[0] = CY + y;
    assign xN[1] = CX - x;//octadrant2
    assign yN[1] = CY + y;
    assign xN[2] = CX + x;//octadrant3
    assign yN[2] = CY - y;
    assign xN[3] = CX - x;//octadrant4
    assign yN[3] = CY - y;
    assign xN[4] = CX + y;//octadrant5
    assign yN[4] = CY + x;
    assign xN[5] = CX - y;//octadrant6
    assign yN[5] = CY + x;
    assign xN[6] = CX + y;//octadrant7
    assign yN[6] = CY - x;
    assign xN[7] = CX - y;//octadrant8
    assign yN[7] = CY - x;
    reg signed [7:0] XO;
    reg signed [6:0] YO;
    reg [2:0] c = 0;
    reg pt8done = 0;
    wire DONE = (y < x);//reached end point
    always @ (posedge CLK) begin//update variable registers
        if (x[0] === 1'bX || pt8done) begin
            e <= E;
            x <= NX;
            y <= NY;
            pt8done <= 0;
        end else begin
            c <= c + 1;
            XO <= xN[c];
            YO <= yN[c];
            pt8done = c == 7 ? 1 : 0;
        end
    end
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
    assign BUSY = loop;
    assign X = XO[6:0];
    assign Y = YO[5:0];
endmodule

module OnSceneSpriteCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    localparam [1:0] SCN = 0;//scene
    localparam [1:0] CHR = 1;//character
    localparam [1:0] EFF = 2;//effect
    wire [6:0] LX = CMD[6:0];
    wire [5:0] TY = CMD[12:7];
    wire [15:0] MASKC = CMD[28:13];
    wire [6:0] INDEX = CMD[35:29];
    wire [1:0] POWER = CMD[37:36];
    wire [15:0] MAP[63:0];
    wire [6:0] RX = LX + (3'd7 << POWER); // 8x8
    wire [5:0] BY = TY + (3'd7 << POWER); // 8x8
    SceneSpriteBlocks CB(INDEX, MAP);
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg [6:0] XO;
    reg [5:0] YO;
    reg [15:0] CO;
    reg [6:0] xcount;
    reg [5:0] ycount;
    wire [3:0] chrX = (xcount - LX) >> POWER;
    wire [3:0] chrY = (ycount - TY) >> POWER;
    wire [7:0] index = 6'd63 - chrX - chrY * 4'd8;
    wire DONE = (xcount == RX && ycount == BY);//reached end point
    always @ (posedge CLK) begin // count x and y and update variables
        if (loop) begin
            if (MAP[index] != MASKC) begin
                XO <= xcount;
                YO <= ycount;
                CO <= MAP[index];
            end
            if (xcount == RX) begin
                xcount <= LX;
                if (ycount == BY) ycount <= TY;
                else ycount <= ycount + 1;
            end else xcount <= xcount + 1;
        end else begin
            xcount <= LX;
            ycount <= TY;
        end
    end
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
    assign BUSY = loop;
    assign X = XO;
    assign Y = YO;
    assign COLOR = CO;
endmodule

module OnFillRectCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] X1 = CMD[6:0];
    wire [5:0] Y1 = CMD[12:7];
    wire [6:0] X2 = CMD[35:29];
    wire [5:0] Y2 = CMD[41:36];
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg [6:0] XO;
    reg [5:0] YO;
    reg [6:0] xcount;
    reg [5:0] ycount;
    wire DONE = (xcount == X2 && ycount == Y2);//reached end point
    always @ (posedge CLK) begin // count x and y and update variables
        if (loop) begin
            if (xcount < X2) xcount <= xcount + 1;
            else begin
                xcount <= X1;
                if (ycount < Y2) ycount <= ycount + 1;
                else ycount <= Y1;
            end
            XO <= xcount;
            YO <= ycount;
        end else begin
            xcount <= X1;
            ycount <= Y1;
        end
    end
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
    assign BUSY = loop;
    assign X = XO;
    assign Y = YO;
endmodule

module OnFillCircCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] CX = CMD[6:0];
    wire [5:0] CY = CMD[12:7];
    wire [4:0] R = CMD[33:29];
    wire [6:0] LX = CX - R;
    wire [5:0] TY = CY - R;
    wire [7:0] RX = CX + R;
    wire [6:0] BY = CY + R;
    assign COLOR = CMD[28:13];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg [6:0] XO;
    reg [5:0] YO;
    reg [6:0] xcount;
    reg [5:0] ycount;
    wire [4:0] dx = xcount > CX ? xcount - CX : CX - xcount;
    wire [4:0] dy = ycount > CY ? ycount - CY : CY - ycount;
    wire [10:0] sum = dx * dx + dy * dy;
    wire [9:0] r2 = R * R;
    wire DONE = (xcount == RX && ycount == BY);//reached end point
    always @ (posedge CLK) begin // count x and y and update variables
        if (loop) begin
            if (r2 >= sum) begin
                XO <= xcount;
                YO <= ycount;
            end
            if (xcount == RX) begin
                xcount <= LX;
                if (ycount == BY) ycount <= TY;
                else ycount <= ycount + 1;
            end else xcount <= xcount + 1;
        end else begin
            xcount <= LX;
            ycount <= TY;
        end
    end
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
    assign BUSY = loop;
    assign X = XO;
    assign Y = YO;
endmodule

module Graphics(input [15:0] sw, input [3:0] Volume, input [3:0] swState, input onRefresh, input WCLK, input [12:0] Pix, output [15:0] STREAM);
    reg [6:0] CmdPushLoc = 0;
    wire [6:0] CmdX;
    wire [5:0] CmdY;
    wire [15:0] CmdCol;
    wire pixSet;
    wire CmdBusy;
    wire NextCmd;
    wire SW_ON = swState > 0;
    //wire validNextCmd = CmdQout[63] == 1;
    wire ReadNext = ~CmdBusy ? WCLK : 0;
    reg [63:0] StartScreenCmd;
    reg [63:0] AudioVisualizationCmd;
    reg cmdPush;
    pulser Psw(SW_ON, WCLK, cmdPush);
    pulser Pbz(~CmdBusy, WCLK, NextCmd);
    wire [63:0] CmdQin;
    wire Builder_WRITE;
    wire [6:0] Builder_WADDR;
    wire [63:0] CmdQout;
    reg [63:0] Cmd;
    reg [6:0] X;
    reg [5:0] Y;
    reg [15:0] C;
    wire GPU_ON;
    wire GPU_BUSY;
    wire [6:0] GPU_RADDR;
    CommandQueue #(128) CMDQ(CmdQin, ~GPU_BUSY, GPU_RADDR, Builder_WRITE, Builder_WADDR, CmdQout);
    GraphicsProcessingUnit GPU(CmdQout, GPU_ON, WCLK, GPU_RADDR, X, Y, C, GPU_BUSY);
    assign Cmd = sw[13] ? AudioVisualizationCmd : StartScreenCmd;
    StartScreenSceneBuilder #(15) SSSB(NextCmd, 2'b0, StartScreenCmd);
    AudioVisualizationSceneBuilder #(34) AVSB(NextCmd, sw[6:5], sw[4], sw[3], sw[2], sw[1], sw[0], Volume, AudioVisualizationCmd);//[6:5]theme,[4]thick,[3]boarder,[2]background,[1]bar,[0]text
    DisplayRAM DRAM(Pix, ~WCLK, WCLK, pixSet, CmdX, CmdY, CmdCol, STREAM); //using negedge of WCLK to read, posedge to write
    /*
    `include "CommandFunctions.v"
    always @ (*) begin//redraw onto the DRAM as a new frame
        if (~CmdBusy) begin
            CmdPushLoc = CmdPushLoc + 1;
            case (swState)
                4'd1: begin Cmd = DrawPoint(7'd48, 6'd32, {5'd31, 6'd63, 5'd31}); end // 1 - point // white point R,G,B
                4'd2: begin Cmd = DrawLine(7'd16, 6'd48, 7'd80, 6'd48, {5'd31,6'd32,5'd0}); end // 2 - line // orange line R,0.5G,0
                4'd3: begin Cmd = DrawChar(7'd46, 6'd29, 20'd5, {5'd0, 6'd0, 5'd31},1'd1); end // 3 - char // blue char 0,0,B
                4'd4: begin Cmd = DrawRect(7'd32, 6'd16, 7'd64, 6'd48, {5'd31,6'd0,5'd0}); end // 4 - rectangle // red rect R,0,0
                4'd5: begin Cmd = DrawCirc(7'd48, 6'd32, 5'd31, {5'd0, 6'd63, 5'd0}); end // 5 - circle // green circle 0,G,0
                4'd6: begin Cmd = DrawSceneSprite(7'd0, 6'd48, {5'd31, 6'd63, 5'd31}, 7'd0); end // 6 - scene sprite // sprite scene[0-grass] 0,48 - 7,55
                4'd7: begin Cmd = FillRect(7'd40, 6'd24, 7'd56, 6'd40, {5'd31,6'd63,5'd0}); end // 7 - fill rectangle // yellow frect R,G,0
                4'd8: begin Cmd = FillCirc(7'd48, 6'd32, 5'd16, {5'd31, 6'd0, 5'd31}); end //8 - fill circle // magenta fcircle R,0,B
                default: begin Cmd = 0; end // 0 - idle
            endcase
        end
    end
    */
endmodule