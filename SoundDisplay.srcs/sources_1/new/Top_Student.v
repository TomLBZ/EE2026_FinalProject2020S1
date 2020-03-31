`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//
//  LAB SESSION DAY (Delete where applicable):  THURSDAY A.M.
//
//  STUDENT A NAME: Liu Jingming
//  STUDENT A MATRICULATION NUMBER: A0204685B
//
//  STUDENT B NAME: Li Bozhao
//  STUDENT B MATRICULATION NUMBER: A0205636H
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input CLK100MHZ, [4:0] btn,[15:0] sw,
    input JAI,
    output [1:0] JAO,
    output [7:0] JB, [15:0] led, [6:0] seg, [3:0] an
    );                  //JAU[0] is pin 1, JAU[1] is pin 4; JAU[2] is pin 3
    reg taskMode = 1;//for lab tasks use 1, for project use 0.
    reg [2:0] clkrst = 0;//reset clock
    wire [15:0] oled_data;// = 16'h07E0;//pixel data to be sent
    reg [4:0] sbit = 5'd21;//slow clock's reading bit. Freq(sclk) = Freq(CLK) / 2^(sbit + 1).
    wire [3:0] volume;//current sound level from 0 to 15
    wire [3:0] graphicsState;//determines state of graphics
    wire [11:0] mic_in;//mic sample input from the mic
    wire [4:0] btnPulses;
    wire [3:0] CLK;//[100M, 6.25M, 20k, _flexible_]
    wire [15:0] mic_mapped;//processed data for led display
    wire [12:0] currentPixel;//current pixel being updated, goes from 0 to 6143.
    wire [4:0] testState;
    wire reset = taskMode ? btnPulses[0] : (clkrst ? 1 : 0);
    wire clk6p25m = CLK[2];
    wire onRefresh;//asserted for 1 clk cycle when drawing new frame on the screen
    wire sendingPixels;
    wire samplePixel;
    wire led_MUX_toggle;
    Peripherals peripherals(CLK100MHZ,clkrst,sbit,btn,sw,CLK,btnPulses,led_MUX_toggle, graphicsState);
    Audio_Capture ac(CLK[3],CLK[1],JAI, JAO[0], JAO[1], mic_in);
    B16_MUX led_mux(mic_mapped,{4'b0,mic_in},led_MUX_toggle,led[15:0]);
    //Oled_Display oled(clk6p25m,reset,onRefresh,sendingPixels,samplePixel,currentPixel,oled_data,JB[0],JB[1],JB[3],JB[4],JB[5],JB[6],JB[7], testState);
    //Graphics g(sw, volume, graphicsState, onRefresh, CLK[3], currentPixel, oled_data);    
    AV_Indicator av1(CLK[3],CLK[1],CLK[0], mic_in,an,seg,mic_mapped,volume);
    
    wire [15:0] game_oled_data;
    wire [15:0] game_playmode_oled_data;
    wire [15:0] game_displaymode_oled_data;
    game_maze(CLK100MHZ,btn[0], btn[1], btn[4], btn[3], btn[2],currentPixel, game_playmode_oled_data);
endmodule