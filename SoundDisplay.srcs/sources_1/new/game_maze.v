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


module game_maze(input CLK, input [12:0] Pix, output reg [15:0] STREAM);
    //reg [29:0] counter = 30'b000000000000000000000000000000;
    reg [12:0] xvalue;
    reg [12:0] yvalue;
    
    always @ (posedge CLK) begin
        //map Pix value to x and y
        //counter <= counter + 1'b1;
        yvalue = Pix / 8'd96;   //0~64
        xvalue = Pix - yvalue * 8'd96;  //0~96
        
        if ((xvalue > 7'd0) && (xvalue<7'd18) && (yvalue > 7'd56) && (yvalue < 7'd64)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd12) && (xvalue<7'd18) && (yvalue > 7'd32) && (yvalue < 7'd56)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd6) && (xvalue<7'd12) && (yvalue > 7'd8) && (yvalue < 7'd40)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd12) && (xvalue<7'd30) && (yvalue > 7'd8) && (yvalue < 7'd16)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd24) && (xvalue<7'd54) && (yvalue > 7'd16) && (yvalue < 7'd24)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd36) && (xvalue<7'd42) && (yvalue > 7'd0) && (yvalue < 7'd16)) STREAM <= 16'b1111100000000000;
        else STREAM <= 16'b0000000000111111;
        
    end
    
endmodule
