`timescale 1ns / 1ps
module simClk();
    reg clk = 0;
    reg [15:0] sw = 2;
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
    //always begin
    //# 1000 sw = sw + 1;
    //end
    Top_Student ts(clk, btns,sw,jai, jao,jb,led);
endmodule