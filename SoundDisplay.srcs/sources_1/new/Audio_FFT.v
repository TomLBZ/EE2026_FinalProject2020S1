`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/01 23:35:53
// Design Name: 
// Module Name: Audio_FFT
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

//1000Hz-----3000Hz  
module Audio_FFT(input [11:0] mic_in,CLK,MCLK,output FREQ);
    reg [11:0] SAMPLE [9999:0];  //Array of sample frequency (10000 samples)
    reg [11:0] freq;
    reg [13:0] c; //counter variable for sampling
    reg [13:0] counter = 0;
    //assign FREQ = freq;
    reg [1:0]FFTCLK;
    FFT_clock clk(MCLK, FFTCLK); 
    
    /* 
    Part 1: Volume Sampling
        Sampling frequency; 20kHz
        Number of samples; 10000
        Period: 0.5 seconds
    */
    // initialisation of the array to 12'b0
    initial begin
        freq = 12'd0;
        for (c = 0; c < 14'd10000;c = c + 1) begin
            SAMPLE[c] = 12'd0;
        end
    end
    //sample volume at 20kHz frequency
    always @(posedge MCLK) begin
        counter <= counter + 1;
        SAMPLE[counter] = mic_in;   //g(t)
    end
    
    /* 
    Part 2: FFT Calculations
    */
    reg REAL;
    reg IMAG;
    //output = arr[input]
    
    
endmodule

/*output clocks of frequency 1000~3000hz*/
module FFT_clock (input MCLK, output [1:0] FFTCLK);  //20kHz
    reg [5:0] counter0 = 6'b000000;
    reg [5:0] counter1 = 6'b000000;
    reg [5:0] counter2 = 6'b000000;
    always@(posedge MCLK)begin
        if (counter0 == 6'd40) counter0 <= 6'd000000;
        else counter0 <= counter0 + 1;
        if (counter1 == 6'd20) counter1 <= 6'd000000;
        else counter1 <= counter1 + 1;
        if (counter2 == 6'd7) counter0 <= 6'd000000;
        else counter2 <= counter2 + 1;       
    end
    assign FFTCLK[0] = (counter0==14'd40);    //500Hz
    assign FFTCLK[1] = (counter1==14'd20);    //1000Hz
    assign FFTCLK[2] = (counter2==14'd7);     //3000Hz
endmodule

