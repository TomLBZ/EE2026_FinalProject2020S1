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
    reg [4:0] vart_1000 = 5'b00001;  //1~20
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
            if(vart_1000==5'd20) begin
                if(final_cal_1000 == 2'b10) begin    //reset after finish all calculations
                    vart_1000<= 5'b00001;
                end
            end
            else vart_1000 <= vart_1000 + 1'b1;
        end
    end
    
    /*
    Part 2: FFT formula inplementation
    for now we have three frequencies, 1000Hz, 2000Hz, 3000Hz,
    */
    reg [28:0] RESULT_1000;
    reg [28:0] REAL_1000;
    reg [28:0] REAL_pos_1000;
    reg [28:0] REAL_neg_1000;
    reg [28:0] IMAG_1000;
    reg [28:0] IMAG_pos_1000;
    reg [28:0] IMAG_neg_1000;
    reg [8:0] angle_1000;   //0~360
    reg [8:0] angle_180_1000;
    reg [6:0] angle_90_1000;
    //(7'b0 ~7'b1011010) (0~90)
    
    reg [12:0] SIN_value_1000;
    reg [12:0] COS_value_1000;
    FFT_sin sin_1000(angle_90_1000, SIN_value_1000);
    FFT_cos cos_1000(angle_90_1000, COS_value_1000);
    
    reg [1:0] final_cal_1000 = 2'b00;
    always @(posedge MCLK) begin
        //angle = (13'd6280 * vart_1000 / 15'd20000) * 9'd360 / 6.28;  // (0~6.28) need to improve the calculation
        angle_1000 = 19'd360000 * vart_1000; //(0~360)
        
        if (angle_1000 < 8'd180) begin   //final value is positive
            if (angle_1000 <= 7'd90) begin
                angle_90_1000 = angle_1000;
                IMAG_pos_1000 <=  IMAG_pos_1000 + mic_in * SIN_value_1000;
            end
            else begin
                angle_90_1000 = angle_1000 - 7'd90; //sin£¨¦Ð/2£«¦Á£©£½cos¦Á
                IMAG_pos_1000 <= IMAG_pos_1000 + mic_in * COS_value_1000;
            end
        end
        else begin //final value is negative  //sin£¨¦Ð£«¦Á£©£½£­sin¦Á
            angle_180_1000 = angle_1000 - 9'd180;
            if (angle_180_1000 <= 7'd90) begin
                angle_90_1000 = angle_1000;
                IMAG_neg_1000 <=  IMAG_neg_1000 + mic_in * SIN_value_1000;
            end
            else begin
                angle_90_1000 = angle_1000 - 7'd90; //sin£¨¦Ð/2£«¦Á£©£½cos¦Á
                IMAG_neg_1000 <= IMAG_neg_1000 + mic_in * COS_value_1000;
          end
        end
        
        if(vart_1000==5'd20) begin
            final_cal_1000 = final_cal_1000 + 1;
            REAL_1000 = REAL_pos_1000 - REAL_neg_1000;
            IMAG_1000 = IMAG_pos_1000 - IMAG_neg_1000;
        end
        if (final_cal_1000 == 2'b01) begin
            RESULT_1000 = IMAG_1000*IMAG_1000 + REAL_1000*REAL_1000;
            final_cal_1000 = final_cal_1000 + 1;
        end
        if (final_cal_1000 -- 2'b10) final_cal_1000 <= 2'b00;
    end

endmodule