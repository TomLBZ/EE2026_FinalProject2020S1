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

module CLOCK10HZ(input CLK100MHZ, output CLK);
    reg clk = 0;
    reg [22:0] accumulator = 0;
    always @ (posedge CLK100MHZ) begin
        accumulator = accumulator + 1'b1;
        if (accumulator == 23'd5000000) clk = ~clk;
    end
    assign CLK = clk ? 1 : 0;
endmodule

module BadApple(input CLK, input ON, input PAUSE, input Clk10Hz, output Write, output [6:0] WX, output [5:0] WY, output [15:0] COLOR);
    localparam [1:0] IDL = 0;//idle
    localparam [1:0] STR = 1;//start drawing
    localparam [1:0] STP = 2;//end drawing
    reg [1:0] STATE = 0;
    always @ (posedge CLK) begin//change state
        case (STATE)
            IDL: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            STR: begin
                if (PAUSE) STATE <= STP;//if done then stop
                else STATE <= STR;//else start
            end
            STP: begin
                if (ON) STATE <= STR;//if on then start
                else STATE <= IDL;//else idle
            end
            default: STATE <= IDL;//default idle
        endcase
    end
    wire Playing = (STATE == STR);
    reg [7:0] BAM [370436:0];//370437 cmds
    parameter MEM_INIT_FILE = "BadAppleMem.mem";
    initial begin
        if (MEM_INIT_FILE != "") begin
            $readmemh(MEM_INIT_FILE, BAM);
        end
    end
    reg [19:0] AddrCount = 0;
    reg [11:0] Frame = 0;
    reg [12:0] PosOnFrame = 0;
    wire [7:0] Data = BAM[AddrCount];
    wire [15:0] C = Data[7] ? 16'b1111111111111111 : 16'd0;
    wire [6:0] LEN = Data[6:0];
    always @ (posedge Clk10Hz) begin
        Frame = Frame + 1;
        if(Frame == 12'd2192) Frame = 0;//max 2191
    end
    always @ (posedge CLK) begin
        PosOnFrame = PosOnFrame + 1;
        if(PosOnFrame == 13'd6144) PosOnFrame = 0;
        if (AddrCount == 20'd370438) AddrCount = 0;
    end
    assign COLOR = C;
endmodule
