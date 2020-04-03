`timescale 1ns / 1ps
module simClk();
    reg clk = 0;
    reg [15:0] sw = 15'b0011000000111100;
    reg [4:0] btns = 0;
    wire jai;
    wire [1:0] jao;
    wire [7:0] jb;
    wire [15:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    always begin
    # 5 clk = ~clk;
    end
    Top_Student ts(clk, jai, btns, sw, jao, jb, led, seg, an); 
endmodule