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
module OnIdleCommand(input CLK, input ON, input [6:0] OldX, input [5:0] OldY, input [15:0] OldC, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    initial STATE = 0;
    wire busy = (STATE == STR);
    always @ (posedge CLK) begin//change state
        case (STATE)
            IDL: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            STR: begin
                if (busy) STATE <= STP;//if done then stop
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
    assign X = OldX;
    assign Y = OldY;
    assign COLOR = OldC;
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
    wire [6:0] RX = LX - 7'd1 + (4'd5 << POWER);
    wire [5:0] BY = TY - 6'd1 + (4'd7 << POWER);
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
    wire [6:0] RX = LX - 7'd1 + (4'd8 << POWER); // 8x8
    wire [5:0] BY = TY - 6'd1 + (4'd8 << POWER); // 8x8
    SceneSpriteBlocks CB(INDEX, MAP);
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    wire loop = (STATE == STR);//if started, then loops
    reg [6:0] XO = LX;
    reg [5:0] YO = TY;
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

module OnSingleBranchCommand(input CLK, input ON, input [63:0] CMD, input [1:0] IMME, input [6:0] OldAddr, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] Dest = CMD[6:0];
    wire [5:0] cmp = CMD[8:7];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    reg drawn = 0;
    wire DONE = drawn;
    wire busy = (STATE == STR);
    reg [6:0] x;
    reg [5:0] y;
    assign x = IMME == cmp[1:0] ? Dest : OldAddr; 
    assign y = IMME == cmp[1:0] ? 6'd1 : 6'd0;   
    always @ (posedge CLK) begin
        if (busy) begin
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
    assign COLOR = 0;
endmodule

module OnDoubleBranchCommand(input CLK, input ON, input [63:0] CMD, input [1:0] IMME, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] Dest1 = CMD[6:0];
    wire [6:0] Dest2 = CMD[13:7];
    wire [5:0] cmp = CMD[15:14];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    reg drawn = 0;
    wire DONE = drawn;
    wire busy = (STATE == STR);
    reg [6:0] x;
    reg [5:0] y;
    assign x = IMME == cmp[1:0] ? Dest1 : Dest2;
    assign y = IMME == cmp[1:0] ? 6'd1 : 6'd0;        
    always @ (posedge CLK) begin
        if (busy) begin
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
    assign COLOR = 0;
endmodule

module OnJumpCommand(input CLK, input ON, input [63:0] CMD, output [6:0] X, output [5:0] Y, output [15:0] COLOR, output BUSY);
    wire [6:0] Dest = CMD[6:0];
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE;//current state
    reg drawn = 0;
    wire DONE = drawn;
    wire busy = (STATE == STR);
    reg [6:0] x;
    reg [5:0] y;
    assign x = Dest;
    assign y = 6'd1;  
    always @ (posedge CLK) begin
        if (busy) begin
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
    assign COLOR = 0;
endmodule

module Graphics(input [15:0] sw, input [3:0] Volume, input onRefresh, input WCLK, input [12:0] Pix, output [15:0] STREAM, output [15:0] debugLED);
    localparam StrSize = 15;
    localparam AV_Size = 34;
    integer SIZE = StrSize + AV_Size;
    wire [63:0] StartScreenCmd;
    wire [6:0] sssbCNT;
    wire StartScreenWriting = sssbCNT == StrSize ? 0 : 1;//finished writing all commands to the queue, then 0
    wire StartScreenClock = StartScreenWriting ? WCLK : 0;
    StartScreenSceneBuilder #(StrSize) SSSB(StartScreenClock, 2'b0, StartScreenCmd, sssbCNT);
    wire [63:0] AudioVisualizationCmd;
    wire [6:0] avsbCNT;
    wire AudioVisualWriting = sssbCNT == StrSize ? (avsbCNT == AV_Size ? 0 : 1) : 0;//finished writing all commands to the queue, then 0
    wire AudioVisualClock = AudioVisualWriting ? WCLK : 0;
    wire [6:0] GPU_RADDR;
    wire AutoRefresh = GPU_RADDR == sssbCNT;
    AudioVisualizationSceneBuilder #(AV_Size) AVSB(AudioVisualClock, onRefresh, sssbCNT, sw[6:5], sw[4], sw[3], sw[2], sw[1], sw[0], Volume, AudioVisualizationCmd, avsbCNT);//[6:5]theme,[4]thick,[3]boarder,[2]background,[1]bar,[0]text
    wire [63:0] CmdQin = StartScreenWriting ? StartScreenCmd : (AudioVisualWriting ? AudioVisualizationCmd : 0);
    wire [63:0] CmdQout;
    wire Builder_WRITE = StartScreenWriting | AudioVisualWriting ? WCLK : 0;//make sure not reading and writing same address
    wire [6:0] Builder_WADDR = StartScreenWriting ? sssbCNT : sssbCNT + avsbCNT;
    wire GPU_DONE;
    wire GPU_BUSY;
    CommandQueue #(128) CMDQ(CmdQin, GPU_DONE, GPU_RADDR, Builder_WRITE, Builder_WADDR, CmdQout);
    wire [6:0] X;
    wire [5:0] Y;
    wire [15:0] C;
    wire GPU_ON = 1;
    wire [1:0] ImmediateState = sw[14:13];
    GraphicsProcessingUnit GPU(CmdQout, GPU_ON, WCLK, ImmediateState, GPU_RADDR, X, Y, C, GPU_DONE, GPU_BUSY);
    wire BACLK;
    wire BA_PLAYING;
    CLOCK10HZ C10(WCLK, BACLK);
    BadApple BA(WCLK, sw[10], ~sw[10], BACLK, BA_PLAYING, X, Y, C);
    DisplayRAM DRAM(Pix, ~WCLK, WCLK, GPU_BUSY | BA_PLAYING, X, Y, C, STREAM); //using negedge of WCLK to read, posedge to write, white when CPU is rendering
endmodule