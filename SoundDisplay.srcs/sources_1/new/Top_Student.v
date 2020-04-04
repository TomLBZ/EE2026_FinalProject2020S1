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
    input CLK100MHZ, JAI, [4:0] btn,[15:0] sw,
    output [1:0] JAO, [7:0] JB, [15:0] led, [6:0] seg, [3:0] an
    ); 
    reg [2:0] clkrst = 0;//reset clock
    reg [4:0] sbit = 5'd22;//slow clock's reading bit. Freq(sclk) = Freq(CLK) / 2^(sbit + 1).
    wire [3:0] CLK;//[100M, 6.25M, 20k, _flexible_]
    wire BadAppleClock;
    wire [15:0] SwStates;//the states of switches
    wire [15:0] SwOnPulses;//contains pulses of "turning on" action of switches
    wire [15:0] SwOffPulses;//contains pulses of "turning off" action of switches
    wire [4:0] BtnStates;//the states of buttons (is pressed and held down or not)
    wire [4:0] BtnPressPulses;//contains pulses of "pressing down" action of buttons
    wire [4:0] BtnReleasePulses;//contains pulses of "releasing up" action of buttons
    Peripherals peripherals(CLK100MHZ, clkrst, sbit, btn, sw, CLK, SwStates, SwOnPulses, SwOffPulses, BtnStates, BtnPressPulses, BtnReleasePulses, BadAppleClock);
    wire reset = BtnStates[0] | (clkrst ? 1 : 0);
    wire [15:0] oled_data;// = 16'h07E0;//pixel data to be sent
    wire [12:0] currentPixel;//current pixel being updated, goes from 0 to 6143.
    wire [4:0] testState;
    wire onRefresh;//asserted for 1 clk cycle when drawing new frame on the screen
    wire sendingPixels;
    wire samplePixel;
    Oled_Display oled(CLK[2],reset,onRefresh,sendingPixels,samplePixel,currentPixel,oled_data,JB[0],JB[1],JB[3],JB[4],JB[5],JB[6],JB[7], testState);
    wire [11:0] mic_in;//mic sample input from the mic
    Audio_Capture ac(CLK[3],CLK[1],JAI, JAO[0], JAO[1], mic_in);
    wire [3:0] volume;//current sound level from 0 to 15
    wire [15:0] mic_mapped;//processed data for led display
    AV_Indicator av1(CLK[3],CLK[1],CLK[0], mic_in,an,seg,mic_mapped,volume);
    B16_MUX led_mux(mic_mapped,{4'b0,mic_in},SwStates[15],led[15:0]);
    wire [1:0] MazeDState;  
    Graphics g(SwStates, volume, onRefresh, CLK[3], BadAppleClock, currentPixel, oled_data, led);  
    
    
    
    //wire [2:0]FREQ;
    //Audio_FFT_discrete fft1(mic_in,CLK100MHZ,CLK[1],FREQ);
    //assign led[2:0] = FREQ;
endmodule