`timescale 1ns / 1ps
module simClk();
    reg clk = 0;
    reg [4:0] btns = 0;
    wire [7:0] jb;
    wire [15:0] led;
    always begin
    # 5 clk = ~clk;
    end
    wire [1:0] out;
    Top_Student ts(clk, btns,0,out[1],out[0],jb,led);
endmodule