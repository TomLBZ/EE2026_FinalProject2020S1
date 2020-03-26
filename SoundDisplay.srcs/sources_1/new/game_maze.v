`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/03/24 11:19:19
// Design Name: 
// Module Name: game_maze
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


module maze_pixel_map (input CLK, input [12:0] Pix, output reg [12:0] xvalue,reg [12:0] yvalue);
    always @ (posedge CLK) begin
        yvalue = Pix / 8'd96;   //0~64
        xvalue = Pix - yvalue * 8'd96;  //0~96
    end      
endmodule

module maze_map(input CLK, [12:0] xvalue, [12:0] yvalue,[12:0] xdot, [12:0] ydot, output reg [1:0]OnRoad);
    always @ (posedge CLK) begin
        if ((xvalue <=  xdot + 1) && (xvalue >= xdot - 1) && (yvalue <=  ydot + 1) && (yvalue >= ydot - 1)) OnRoad = 2'b11;
        else begin 
            if ((xvalue >= 7'd0) && (xvalue<=7'd18) && (yvalue >= 7'd56) && (yvalue <= 7'd64)) OnRoad = 0;
            else if ((xvalue >= 7'd12) && (xvalue<=7'd18) && (yvalue >= 7'd32) && (yvalue <= 7'd56)) OnRoad = 0;
            else if ((xvalue >= 7'd6) && (xvalue<=7'd12) && (yvalue >= 7'd8) && (yvalue <= 7'd40)) OnRoad = 0;
            else if ((xvalue >= 7'd12) && (xvalue<=7'd30) && (yvalue >= 7'd8) && (yvalue <= 7'd16)) OnRoad = 0;
            else if ((xvalue >= 7'd24) && (xvalue<=7'd54) && (yvalue >= 7'd16) && (yvalue <= 7'd24)) OnRoad = 0;
            else if ((xvalue >= 7'd36) && (xvalue<=7'd42) && (yvalue >= 7'd0) && (yvalue <= 7'd16)) OnRoad = 0;
            else if ((xvalue >= 7'd42) && (xvalue<=7'd66) && (yvalue >= 7'd0) && (yvalue <= 7'd8)) OnRoad = 0;
            else if ((xvalue >= 7'd36) && (xvalue<=7'd42) && (yvalue >= 7'd0) && (yvalue <= 7'd16)) OnRoad = 0;
            else if ((xvalue >= 7'd60) && (xvalue<=7'd66) && (yvalue >= 7'd8) && (yvalue <= 7'd40)) OnRoad = 0;
            else if ((xvalue >= 7'd48) && (xvalue<=7'd60) && (yvalue >= 7'd24) && (yvalue <= 7'd32)) OnRoad = 0;
            else if ((xvalue >= 7'd30) && (xvalue<=7'd54) && (yvalue >= 7'd32) && (yvalue <= 7'd40)) OnRoad = 0;
            else if ((xvalue >= 7'd30) && (xvalue<=7'd36) && (yvalue >= 7'd40) && (yvalue <= 7'd48)) OnRoad = 0;
            else if ((xvalue >= 7'd18) && (xvalue<=7'd60) && (yvalue >= 7'd48) && (yvalue <= 7'd56)) OnRoad = 0;
            else if ((xvalue >= 7'd84) && (xvalue<=7'd90) && (yvalue >= 7'd40) && (yvalue <= 7'd64)) OnRoad = 0;
            else if ((xvalue >= 7'd72) && (xvalue<=7'd84) && (yvalue >= 7'd40) && (yvalue <= 7'd48)) OnRoad = 0;
            else if ((xvalue >= 7'd66) && (xvalue<=7'd72) && (yvalue >= 7'd24) && (yvalue <= 7'd32)) OnRoad = 0;
            else if ((xvalue >= 7'd72) && (xvalue<=7'd80) && (yvalue >= 7'd16) && (yvalue <= 7'd40)) OnRoad = 0;
            else if ((xvalue >= 7'd80) && (xvalue<=7'd92) && (yvalue >= 7'd16) && (yvalue <= 7'd24)) OnRoad = 0;
            else if ((xvalue >= 7'd84) && (xvalue<=7'd90) && (yvalue >= 7'd0) && (yvalue <= 7'd16)) OnRoad = 0;
            else OnRoad = 2'b01;
        end
        
    end
endmodule

module maze_map_color(input CLK, [2:0] OnRoad, output reg [15:0] STREAM);
    always @ (posedge CLK) begin
        if (OnRoad == 2'b00) STREAM = 16'b1101100000000000;     //red
        else if (OnRoad == 2'b01) STREAM = 16'b0000000111100000;   //green 
        else if (OnRoad == 2'b11) STREAM = 16'b0000000000001111;   //blue
    end
endmodule

//Button Debouncing
module my_dff (input CLOCK, D, output reg Q = 0);
    always @ (posedge CLOCK) Q <= D;
endmodule
module task1(input CLOCK, BTN, output Q);
    wire Q1;
    wire Q2;
    my_dff f0(CLOCK, BTN, Q1);
    my_dff f1(CLOCK, Q1, Q2);
    assign Q = (Q1 & ~Q2);
endmodule

module maze_dot_movement (input CLK, BTNC,BTNU, BTND, BTNR, BTNL, output reg [12:0] xdot,reg [12:0] ydot);
    wire QC; wire QU; wire QD; wire QR; wire QL;
    task1 ef0(CLK, BTNC, QC);
    task1 ef1(CLK, BTNU, QU);
    task1 ef2(CLK, BTND, QD);
    task1 ef3(CLK, BTNR, QR);
    task1 ef4(CLK, BTNL, QL);
    
    reg gamestart = 1'b0;
    always@(posedge CLK) begin
        if(QC == 1) gamestart = 1'b1;
        if(gamestart == 0) begin  
            xdot = 12'd6;
            ydot = 12'd60;
        end
        else begin
            if(QL==1) xdot <= xdot - 1;
            if(QR==1) xdot <= xdot + 1;
            if(QU==1) ydot <= ydot - 1;
            if(QD==1) ydot <= ydot + 1;
        end
    end
endmodule

module game_maze(input CLK,BTNC,BTNU, BTND, BTNR, BTNL, [12:0] Pix, STREAM);
    wire [12:0] xvalue;
    wire [12:0] yvalue;
    wire [12:0] xdot;
    wire [12:0] ydot;
    wire [1:0] OnRoad;
    maze_pixel_map fo(CLK, Pix, xvalue,yvalue);
    maze_map f1(CLK,xvalue,yvalue,xdot, ydot, OnRoad);
    maze_map_color f2(CLK, OnRoad, STREAM);
    maze_dot_movement (CLK, BTNC,BTNU, BTND, BTNR, BTNL, xdot, ydot);
endmodule