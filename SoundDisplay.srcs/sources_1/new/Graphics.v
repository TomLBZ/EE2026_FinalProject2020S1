`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// Create Date: 03/13/2020 09:51:11 AM
// Design Name: FGPA Project for EE2026
// Module Name: PixelSetter, DrawPoint, DrawLine, DrawChar, DrawSceneSprite, DrawRect, DrawCirc, FillRect, FillCirc, 
//              OnPointCommand, OnLineCommand, OnCharCommand, OnSceneSpriteCommand, OnRectCommand, OnCircCommand, OnFillRectCommand, OnFillCircCommand, 
//              Graphics
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module can be used to draw geometric shapes and texts conveniently.
// Dependencies: MemoryBlocks.v
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module PixelSetter(input CLK, input ON, input [6:0] X, input [5:0] Y, input [15:0] COLOR, output [6:0] XO, output [5:0] YO, output [15:0] CO, output WR);
    reg write = 0;
    always @ (posedge CLK) write = ON ? 1 : 0;
    assign XO = X;
    assign YO = Y;
    assign CO = COLOR;
    assign WR = write;
endmodule

module DrawPoint(input [6:0] X, input [5:0] Y, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X,[7:12]Y,[13:28]C
    always @ (X, Y, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd1;//PT
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
    end
    assign CMD = cmd;
endmodule

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

module DrawLine(input [6:0] X1, input [5:0] Y1, input [6:0] X2, input [5:0] Y2, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    always @ (X1, Y1, X2, Y2, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd2;//LN
        cmd[6:0] <= X1;
        cmd[12:7] <= Y1;
        cmd[28:13] <= COLOR;
        cmd[35:29] <= X2;
        cmd[41:36] <= Y2;
    end
    assign CMD = cmd;
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

module DrawChar(input [6:0] X, input [5:0] Y, input [29:0] CHR, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd; //cmd[0:6]X,[7:12]Y,[13:28]C,[29:58]CHR//30-bit char set{[29:54]AZ,[55:58]", . [ ]"}
    always @ (X, Y, CHR, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd3;//CHR
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
        cmd[58:29] <= CHR;
    end
    assign CMD = cmd;
endmodule

module OnCharCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] LX = CMD[6:0];
    wire [5:0] TY = CMD[12:7];
    wire [29:0] CHR = CMD[58:29];
    wire [34:0] MAP;
    wire [6:0] RX = LX + 3'd4;
    wire [5:0] BY = TY + 3'd6;
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
    wire [2:0] chrX = xcount - LX;
    wire [2:0] chrY = ycount - TY;
    wire [5:0] index = chrX + (3'd6 - chrY) * 3'd5;
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

module DrawRect(input [6:0] X1, input [5:0] Y1, input [6:0] X2, input [5:0] Y2, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    always @ (X1, Y1, X2, Y2, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd4;//RECT
        cmd[6:0] <= X1;
        cmd[12:7] <= Y1;
        cmd[28:13] <= COLOR;
        cmd[35:29] <= X2;
        cmd[41:36] <= Y2;
    end
    assign CMD = cmd;
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

module DrawCirc(input [6:0] X, input [5:0] Y, input [4:0] R, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    always @ (X, Y, R, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd5;//CIRC
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
        cmd[33:29] <= R;
    end
    assign CMD = cmd;
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

module DrawSceneSprite(input [6:0] X, input [5:0] Y, input [6:0] INDEX, output [63:0] CMD);
    reg [63:0] cmd;    //cmd[0:6]X,[7:12]Y,[13:19]INDEX
    always @ (X, Y, INDEX) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd6;//SPRSCN
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[19:13] <= INDEX;
    end
    assign CMD = cmd;
endmodule

module OnSceneSpriteCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    localparam [1:0] SCN = 0;//scene
    localparam [1:0] CHR = 1;//character
    localparam [1:0] EFF = 2;//effect
    wire [6:0] LX = CMD[6:0];
    wire [5:0] TY = CMD[12:7];
    wire [6:0] INDEX = CMD[19:13];
    wire [15:0] MAP[255:0];
    wire [6:0] RX = LX + 4'd15; // 16x16
    wire [5:0] BY = TY + 4'd15; // 16x16
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
    wire [3:0] chrX = xcount - LX;
    wire [3:0] chrY = ycount - TY;
    wire [7:0] index = chrX + chrY * 5'd16;
    wire DONE = (xcount == RX && ycount == BY);//reached end point
    always @ (posedge CLK) begin // count x and y and update variables
        if (loop) begin
            XO <= xcount;
            YO <= ycount;
            CO <= MAP[8'd255 - index];
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

module FillRect(input [6:0] X1, input [5:0] Y1, input [6:0] X2, input [5:0] Y2, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X1,[7:12]Y1,[13:28]C,[29:35]X2,[36:41]Y2
    always @ (X1, Y1, X2, Y2, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd7;//FRECT
        cmd[6:0] <= X1;
        cmd[12:7] <= Y1;
        cmd[28:13] <= COLOR;
        cmd[35:29] <= X2;
        cmd[41:36] <= Y2;
    end
    assign CMD = cmd;
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

module FillCirc(input [6:0] X, input [5:0] Y, input [4:0] R, input [15:0] COLOR, output [63:0] CMD);
    reg [63:0] cmd;//cmd[0:6]X,[7:12]Y,[13:28]C,[29:33]R
    always @ (X, Y, R, COLOR) begin
        cmd[63] <= 1;//Enable
        cmd[62:59] <= 4'd8;//FCIRC
        cmd[6:0] <= X;
        cmd[12:7] <= Y;
        cmd[28:13] <= COLOR;
        cmd[33:29] <= R;
    end
    assign CMD = cmd;
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

module Graphics(input [3:0] swState, input onRefresh, input WCLK, input [12:0] Pix, output [15:0] STREAM);
    reg [63:0] Cmd;
    wire [63:0] PTcmd;
    wire [63:0] LNcmd;
    wire [63:0] CHRcmd;
    wire [63:0] RECTcmd;
    wire [63:0] CIRCcmd;
    wire [63:0] SPRSCNcmd;
    wire [63:0] FRECTcmd;
    wire [63:0] FCIRCcmd;
    wire [6:0] CmdX;
    wire [5:0] CmdY;
    wire [15:0] CmdCol;
    wire pixSet;
    wire CmdBusy;
    wire [6:0] psX;
    wire [5:0] psY;
    wire [15:0] psC;
    wire write;
    wire CMD_ON = swState > 0;
    wire CommandDone;//add command queue later, this will be useful.
    DisplayCommandCore DCMD(Cmd, CMD_ON, WCLK, pixSet, CmdX, CmdY, CmdCol, CmdBusy,CommandDone);
    PixelSetter PSET(WCLK,pixSet,CmdX,CmdY,CmdCol,psX,psY,psC,write);
    DisplayRAM DRAM(Pix, WCLK, write, psX, psY, psC, STREAM);
    DrawPoint DPT(7'd48, 6'd32, {5'd31, 6'd63, 5'd31}, PTcmd); // white point R,G,B
    DrawLine DLN(7'd16, 6'd48, 7'd80, 6'd48, {5'd31,6'd32,5'd0}, LNcmd); // orange line R,0.5G,0
    DrawChar DCHR(7'd46, 6'd29, 30'd0, {5'd0, 6'd0, 5'd31}, CHRcmd); // blue char 0,0,B
    DrawRect DRECT(7'd32, 6'd16, 7'd64, 6'd48, {5'd31,6'd0,5'd0}, RECTcmd); // red rect R,0,0
    DrawCirc DCIRC(7'd48, 6'd32, 5'd31, {5'd0, 6'd63, 5'd0}, CIRCcmd); // green circle 0,G,0
    DrawSceneSprite DSS(7'd0, 6'd48, 7'd0, SPRSCNcmd); // sprite scene[0-brick] 0,48 - 15,63
    FillRect FRECT(7'd40, 6'd24, 7'd56, 6'd40, {5'd31,6'd63,5'd0}, FRECTcmd); // yellow frect R,G,0
    FillCirc FCIRC(7'd48, 6'd32, 5'd16, {5'd31, 6'd0, 5'd31}, FCIRCcmd); // magenta fcircle R,0,B
    always @ (*) begin//redraw onto the DRAM as a new frame
        if(~CmdBusy) begin
            case (swState)
                4'd1: begin Cmd = PTcmd; end // 1 - point
                4'd2: begin Cmd = LNcmd; end // 2 - line
                4'd3: begin Cmd = CHRcmd; end // 3 - char
                4'd4: begin Cmd = RECTcmd; end // 4 - rectangle
                4'd5: begin Cmd = CIRCcmd; end // 5 - circle
                4'd6: begin Cmd = SPRSCNcmd; end // 6 - scene sprite
                4'd7: begin Cmd = FRECTcmd; end // 7 - fill rectangle
                4'd8: begin Cmd = FCIRCcmd; end //8 - fill circle
                default: begin Cmd = 0; end // 0 - idle
            endcase
        end
    end
endmodule