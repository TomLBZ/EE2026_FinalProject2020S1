`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/04 00:31:46
// Design Name: 
// Module Name: Audio_FFT_top
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
module Audio_FFT_top(input [11:0] mic_in,CLK,MCLK,output reg [2:0]FREQ);
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
            FREQ = (result[0]>result[1] && result[0]>result[2]) ? 3'b001 : (result[1]>result[2])? 3'b011:3'b111;
        end
        else begin
            counter <= counter + 1;    
            SAMPLE[counter] = mic_in;   //g(t)
        end
    end
    
    /* 
    Part 2: FFT Calculations
    */
    reg [11:0] REAL [2:0]; // g(t) cos(2 pi f t)
    reg [11:0] IMAG [2:0];
    reg [90:0] angle0;
    reg [90:0] angle1;
    reg [90:0] angle2;
    //reg frequency0 = 10'd1000;
    reg [13:0] k0;
    reg [13:0] k1;
    reg [13:0] k2;
    wire [12:0] SIN_value [2:0];
    wire [12:0] COS_value [2:0];
    reg [24:0] result [2:0];
    
    always@(posedge FFTCLK[0])begin      //frequency = 1000Hz
        if(k0 == 14'd1000) begin 
            k0<=14'd0;
            result[0] <= REAL[0]*REAL[0] + IMAG[0]*IMAG[0]; 
        end
        else k0<=k0+1;
        
        angle0 <= (10'd628 * k0 * counter) /(20'd1000000);
        REAL[0] <= REAL[0] + (SAMPLE[counter] * COS_value[0]) / (13'd4096 * 14'd500);
        IMAG[0] <= IMAG[0] + (SAMPLE[counter] * SIN_value[0]) / (13'd4096 * 14'd500);
    end
    FFT_sin f0(angle0, SIN_value[0]);
    FFT_cos f1(angle0, COS_value[0]);
    //output = arr[input]
    
    always@(posedge FFTCLK[1])begin
            if(k1 == 14'd2000) begin 
                k1<=14'd0;
                result[1] <= REAL[1]*REAL[1] + IMAG[1]*IMAG[1]; 
            end
            else k1<=k1+1;
            
            angle1 <= (10'd628 * k1 * counter) /(20'd1000000);
            REAL[1] <= REAL[1] + (SAMPLE[counter] * COS_value[1]) / (13'd4096 * 14'd1000);
            IMAG[1] <= IMAG[1] + (SAMPLE[counter] * SIN_value[1]) / (13'd4096 * 14'd1000);
        end
        FFT_sin f2(angle1, SIN_value[1]);
        FFT_cos f3(angle1, COS_value[1]);
        
        
        always@(posedge FFTCLK[2])begin
                if(k2 == 14'd3000) begin 
                    k2<=14'd0;
                    result[2] <= REAL[2]*REAL[2] + IMAG[2]*IMAG[2]; 
                end
                else k2<=k2+1;
                
                angle2 <= (10'd628 * k0 * counter) /(20'd1000000);
                REAL[2] <= REAL[2] + (SAMPLE[counter] * COS_value[2]) / (13'd4096 * 14'd3000);
                IMAG[2] <= IMAG[2] + (SAMPLE[counter] * SIN_value[2]) / (13'd4096 * 14'd3000);
            end
            FFT_sin f4(angle2, SIN_value[2]);
            FFT_cos f5(angle2, COS_value[2]);
endmodule



/*
output clocks of frequency 1000~3000hz
*/
module FFT_clock (input MCLK, output reg [2:0] FFTCLK);  //20kHz
    reg [5:0] counter0 = 6'b000000;
    reg [5:0] counter1 = 6'b000000;
    reg [5:0] counter2 = 6'b000000;
    always@(posedge MCLK)begin
        if (counter0 == 6'd20) begin  //1000
            counter0 <= 6'd000000;
            FFTCLK[0]<= ~FFTCLK[0];
        end
        else counter0 <= counter0 + 1;
        if (counter1 == 6'd10) begin  //2000
            counter1 <= 6'd000000;
            FFTCLK[1]<= ~FFTCLK[1];
        end
        else counter1 <= counter1 + 1;
        if (counter2 == 6'd7) begin   //3000
            counter0 <= 6'd000000;
            FFTCLK[2]<= ~FFTCLK[2];
        end
        else counter2 <= counter2 + 1;       
    end
endmodule
