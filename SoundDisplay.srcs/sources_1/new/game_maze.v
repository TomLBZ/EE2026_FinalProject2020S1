`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Liu Jingming
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

module maze_pixel_mapping (input CLK, input [12:0] Pix, output reg [12:0] xvalue,reg [12:0] yvalue);
    always @ (posedge CLK) begin
        yvalue = Pix / 8'd96;   //0~64
        xvalue = Pix - yvalue * 8'd96;  //0~96
    end      
endmodule

module maze_map(input CLK, [12:0] xvalue, [12:0] yvalue,[12:0] xdot, [12:0] ydot, output reg [1:0]OnRoad);
    always @ (posedge CLK) begin
            if ((xvalue <=  xdot + 1) && (xvalue >= xdot - 1) && (yvalue <=  ydot + 1) && (yvalue >= ydot - 1)) OnRoad = 2'b10;
            else if ((xvalue >= 7'd0) && (xvalue<=7'd18) && (yvalue >= 7'd56) && (yvalue <= 7'd64)) OnRoad = 0;
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
            else if ((xvalue >= 7'd84) && (xvalue<=7'd90) && (yvalue >= 7'd0) && (yvalue <= 7'd8)) OnRoad = 2'b11;
            else OnRoad = 2'b01; 
    end
endmodule

module maze_map_color(input [2:0] OnRoad,output reg [15:0] STREAM);
    always @ (*) begin
        if (OnRoad == 2'b10) STREAM = 16'b1111111111111111;   //dot
        else if (OnRoad == 0) STREAM = 16'h6C12;     //wall
        else if (OnRoad == 1) STREAM = 16'h24A7;   //road
        else if (OnRoad == 2'b11) STREAM = 16'b0000000000111111;
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

module maze_dot_movement (input CLK, BTNC,BTNU, BTND, BTNR, BTNL, validmove, output reg [12:0] xdot,reg [12:0] ydot, reg [1:0] gamestart = 2'b00);
    wire QC; wire QU; wire QD; wire QR; wire QL;
    task1 ef0(CLK, BTNC, QC);
    task1 ef1(CLK, BTNU, QU);
    task1 ef2(CLK, BTND, QD);
    task1 ef3(CLK, BTNR, QR);
    task1 ef4(CLK, BTNL, QL);
    
    always@(posedge CLK) begin
        if(QC == 1) begin 
            gamestart = 2'b01;   //display gamestart
        end
        if(gamestart == 0) begin  
            xdot = 12'd6;
            ydot = 12'd60;
        end
        else begin
            if (validmove == 1) begin
                if(QL==1) xdot <= xdot - 1;
                if(QR==1) xdot <= xdot + 1;
                if(QU==1) ydot <= ydot - 1;
                if(QD==1) ydot <= ydot + 1;
            end
        end
    end
endmodule

module maze_checkwall(input CLK, [12:0] xvalue, [12:0] yvalue, output reg onwall);
     always @ (*) begin
                  if ((xvalue >= 7'd0) && (xvalue<=7'd18) && (yvalue >= 7'd56) && (yvalue <= 7'd64)) onwall=1;
                  else if ((xvalue >= 7'd12) && (xvalue<=7'd18) && (yvalue >= 7'd32) && (yvalue <= 7'd56)) onwall=1;
                  else if ((xvalue >= 7'd6) && (xvalue<=7'd12) && (yvalue >= 7'd8) && (yvalue <= 7'd40)) onwall=1;
                  else if ((xvalue >= 7'd12) && (xvalue<=7'd30) && (yvalue >= 7'd8) && (yvalue <= 7'd16)) onwall=1;
                  else if ((xvalue >= 7'd24) && (xvalue<=7'd54) && (yvalue >= 7'd16) && (yvalue <= 7'd24)) onwall=1;
                  else if ((xvalue >= 7'd36) && (xvalue<=7'd42) && (yvalue >= 7'd0) && (yvalue <= 7'd16)) onwall=1;
                  else if ((xvalue >= 7'd42) && (xvalue<=7'd66) && (yvalue >= 7'd0) && (yvalue <= 7'd8)) onwall=1;
                  else if ((xvalue >= 7'd36) && (xvalue<=7'd42) && (yvalue >= 7'd0) && (yvalue <= 7'd16)) onwall=1;
                  else if ((xvalue >= 7'd60) && (xvalue<=7'd66) && (yvalue >= 7'd8) && (yvalue <= 7'd40)) onwall=1;
                  else if ((xvalue >= 7'd48) && (xvalue<=7'd60) && (yvalue >= 7'd24) && (yvalue <= 7'd32)) onwall=1;
                  else if ((xvalue >= 7'd30) && (xvalue<=7'd54) && (yvalue >= 7'd32) && (yvalue <= 7'd40)) onwall=1;
                  else if ((xvalue >= 7'd30) && (xvalue<=7'd36) && (yvalue >= 7'd40) && (yvalue <= 7'd48)) onwall=1;
                  else if ((xvalue >= 7'd18) && (xvalue<=7'd60) && (yvalue >= 7'd48) && (yvalue <= 7'd56)) onwall=1;
                  else if ((xvalue >= 7'd84) && (xvalue<=7'd90) && (yvalue >= 7'd40) && (yvalue <= 7'd64)) onwall=1;
                  else if ((xvalue >= 7'd72) && (xvalue<=7'd84) && (yvalue >= 7'd40) && (yvalue <= 7'd48)) onwall=1;
                  else if ((xvalue >= 7'd66) && (xvalue<=7'd72) && (yvalue >= 7'd24) && (yvalue <= 7'd32)) onwall=1;
                  else if ((xvalue >= 7'd72) && (xvalue<=7'd80) && (yvalue >= 7'd16) && (yvalue <= 7'd40)) onwall=1;
                  else if ((xvalue >= 7'd80) && (xvalue<=7'd92) && (yvalue >= 7'd16) && (yvalue <= 7'd24)) onwall=1;
                  else if ((xvalue >= 7'd84) && (xvalue<=7'd90) && (yvalue >= 7'd0) && (yvalue <= 7'd16)) onwall=1;
                  else onwall=0; 
     end
endmodule

module maze_valid_move (input CLK, [12:0] xdot, [12:0] ydot, onwall, output reg validmove=1);
    maze_checkwall mvm0(CLK, xdot, ydot, onwall);
    always @ (posedge CLK) begin
        if(onwall==1) validmove <= 0;
        else validmove <= 1;
    end
endmodule

module maze_win (input CLK, [12:0] xvalue, [12:0] yvalue, output reg win);
    always @ (posedge CLK) begin
        if ((xvalue >= 7'd84) && (xvalue<=7'd90) && (yvalue >= 7'd0) && (yvalue <= 7'd8)) win<=1;
        else win <= 0;
    end
endmodule


module MazeSceneBuilder_temp(input CLK, input [1:0] MazeDState, output [15:0] STREAM);
    reg [15:0] stream;
    always @(posedge CLK) begin
        if(MazeDState==2'b01) stream = 16'b1111000000000000; //GAME START
        if(MazeDState==2'b10) stream = 16'b0000111110000000; //WIN
        if(MazeDState==2'b11) stream = 16'b0000000000001111; //LOSE
    end
    assign STREAM = stream;
endmodule

//The main module
module game_maze(input CLK,BTNC,BTNU, BTND, BTNR, BTNL, [12:0] Pix, STREAM);
    wire [12:0] xvalue;
    wire [12:0] yvalue;
    wire [12:0] xdot;
    wire [12:0] ydot;
    wire [1:0] OnRoad;
    wire validmove;
    reg [2:0] gamestate=3'd0;
    wire [1:0] gamestart;
    reg [40:0] counter = 41'd0;
    wire win;
    wire [15:0] stream1;
    wire [15:0] stream2;
    wire [15:0] oled_playmode;
    wire [15:0] oled_display;
    wire [1:0] sel;
    reg [1:0] MazeDState = 2'b00;
    reg DisplayControl;
    
    maze_pixel_mapping f0(CLK, Pix, xvalue,yvalue);
    maze_map f1(CLK,xvalue,yvalue,xdot, ydot, OnRoad);
    maze_map_color f2(OnRoad, oled_playmode);   //play mode display (STREAM)
    maze_valid_move f3(CLK, xdot, ydot, validmove);
    maze_dot_movement f4(CLK,BTNC,BTNU, BTND, BTNR, BTNL,validmove, xdot, ydot, gamestart);
    maze_win f5(CLK, xdot, ydot, win); 
    
    assign STREAM = DisplayControl? oled_display : oled_playmode;
    //B16_MUX f7(stream2,stream1,sel[0],oled_playmode); 
    //MazeSceneBuilder MSB(CLK, MazeState, oled_display);
    
    //Below are a series of modules that output the three game scenes (GAMESTART, WIN, LOSE)
    reg [63:0] Cmd;
    wire [6:0] CmdX;
    wire [5:0] CmdY;
    wire [15:0] CmdCol;
    wire pixSet;
    wire CmdBusy;
    
    MazeSceneBuilder_temp(CLK, MazeDState, oled_display);
    //MazeSceneBuilder MSB(CLK, MazeDState, Cmd); //scene mode display (STREAM)
    //DisplayCommandCore DCMD(Cmd, DisplayControl, CLK, pixSet, CmdX, CmdY, CmdCol, CmdBusy);
    //DisplayRAM DRAM(Pix, ~CLK, CLK, pixSet, CmdX, CmdY, CmdCol, oled_display);   //scene mode display (STREAM)
    
    //Finite State Machine for maze game
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//gamestart 
    localparam [1:0] STP = 2;//display WIN/LOSE
    reg [1:0] STATE;
    wire ON = gamestart;  //once gamestart=1, will change from IDL to STR
    wire DONE = (~validmove)||win;  //once validmove=0 or win=1, will change from STR to STP
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
    
    always@(*)begin
        case (STATE)
            IDL: begin  //gamestart = 2'b00;
                MazeDState = 2'b01;
                DisplayControl = 1;
            end
            STR: begin
                DisplayControl = 0; 
            end
            STP: begin
                if(validmove==1'b0) begin
                    MazeDState = 2'b11;
                    DisplayControl = 1;
                end
                else if (win == 1'b1) begin 
                    MazeDState = 2'b10;
                    DisplayControl = 1;
                end
            end
        endcase
    end
endmodule