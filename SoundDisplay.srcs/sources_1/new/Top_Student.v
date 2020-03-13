`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//
//  LAB SESSION DAY (Delete where applicable):  THURSDAY A.M.
//
//  STUDENT A NAME: Liu Jingming
//  STUDENT A MATRICULATION NUMBER: 
//
//  STUDENT B NAME: Li Bozhao
//  STUDENT B MATRICULATION NUMBER: A0205636H
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input CLK100MHZ,
    input [4:0] btn,
    output [2:0] JAU,
    output [7:0] JB,
    output [15:0] led
    );                  //JAU[0] is pin 1, JAU[1] is pin 4; JAU[2] is pin 3
    reg taskMode = 1;//for lab tasks use 1, for project use 0.
    reg [2:0] rst = 0;
    reg [15:0] oled_data = 16'h07E0;//pixel data to be sent
    reg [4:0] sbit = 0;//slow clock's reading bit. Freq(sclk) = Freq(CLK) / 2^(sbit + 1).
    wire [4:0] btnPulses;
    wire [3:0] CLK;//[100M, 6.25M, 20k, _flexible_]
    wire [11:0] mic_in;//mic sample input from the mic
    wire [12:0] currentPixel;//current pixel being updated, goes from 0 to 6143.
    wire [4:0] testState;
    wire reset = taskMode ? btnPulses[0] : (rst ? 1 : 0);
    wire clk6p25m = CLK[2];
    wire onRefresh;//asserted for 1 clk cycle when drawing new frame on the screen
    wire sendingPixels;
    wire samplePixel;
    Peripherals peripherals(CLK100MHZ,rst,sbit,btn,CLK,btnPulses);
    //Audio_Capture(CLK, cs, MISO, clk_samp, sclk, sample);
    Audio_Capture ac(CLK[3],CLK[1],JAU[2], JAU[0], JAU[1], mic_in);
    B12_MUX led_mux(mic_in,0,JAU[2],led[11:0]);
    //Oled_Display(clk, reset, frame_begin, sending_pixels,sample_pixel, pixel_index, pixel_data, cs, sdin, sclk, d_cn, resn, vccen,pmoden,teststate);
    Oled_Display oled(clk6p25m,reset,onRefresh,sendingPixels,samplePixel,currentPixel,oled_data,JB[0],JB[1],JB[3],JB[4],JB[5],JB[6],JB[7], testState);
endmodule