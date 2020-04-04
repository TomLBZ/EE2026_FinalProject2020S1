`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/04 14:59:24
// Design Name: 
// Module Name: Audio_FFT_discrete
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
module Audio_FFT_discrete(input [11:0] mic_in,CLK,MCLK,output reg [2:0]FREQ);
    reg [11:0] SAMPLE [9999:0];  //Array of sample frequency (10000 samples)
    reg [11:0] freq;
    reg [13:0] c; //counter variable for sampling
    reg [13:0] counter = 0;
    wire [2:0]FFTCLK;
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
        if (counter == 14'd9999) begin
        //reset counter value after the calculations are done
        end
        else begin
            counter <= counter + 1;    
            SAMPLE[counter] = mic_in;   //g(t)
        end
    end
    
    
    /*
    Part 2: FFT formula inplementation
    for now we have three frequencies, 1000Hz, 2000Hz, 3000Hz
    
    */
    
endmodule