`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2020 09:55:35 AM
// Design Name: 
// Module Name: BadApple
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module plays BadApple!
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BadApple(input CLK, input [12:0] INDEX, output [15:0] COLOR);
    reg [6143:0] BA [2191:0];
    reg [11:0] Frame = 0;
    reg [15:0] C;
    always @ (posedge CLK) begin
        C = BA[Frame][INDEX] == 0 ? 16'd0 : 16'b1111111111111111;
        if (INDEX == 6143) begin
            Frame = Frame + 1;
        end
    end
    assign COLOR = C;
endmodule
