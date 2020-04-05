`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Liu Jingming
// Create Date: 2020/04/04 14:59:24
// Design Name: FGPA Project for EE2026
// Module Name: Audio_FFT_discrete
// Project Name: FGPA Project for EE2026
// Target Devices: Basys 3
// Tool Versions: Vivado 2018.2
// Description: This module calculates fast fourier transformation and match audio input to the closest frequency among 1000Hz, 2000Hz and 3000Hz.
// Dependencies: NULL
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

//1000Hz-----3000Hz  
module Audio_FFT_discrete(input [11:0] mic_in,CLK,MCLK,output reg [2:0]FREQ);
    reg [11:0] SAMPLE [9999:0];  //Array of sample frequency (10000 samples)
    reg [11:0] freq;
    reg [13:0] c; //counter variable for sampling
    reg [13:0] counter = 14'b00000000000000;
    wire [2:0]FFTCLK;
    reg [4:0] vart_1000 = 5'b00001;  //1~20
    reg [4:0] vart_2000 = 5'b00001;  //change
    reg [4:0] vart_3000 = 5'b00001;  //change
    //FFT_clock clk(MCLK, FFTCLK); 
    reg [28:0] RESULT_1000 = 29'b0;
    reg [28:0] REAL_1000= 29'b0;
    reg [28:0] REAL_pos_1000= 29'b0;
    reg [28:0] REAL_neg_1000= 29'b0;
    reg [28:0] IMAG_1000= 29'b0;
    reg [28:0] IMAG_pos_1000= 29'b0;
    reg [28:0] IMAG_neg_1000= 29'b0;
    reg [8:0] angle_1000;   //0~360
    reg [8:0] angle_180_1000;
    reg [6:0] angle_90_1000;
    wire [12:0] SIN_value_1000;
    wire [12:0] COS_value_1000;
    reg [1:0] final_cal_1000 = 2'b00;
    
    reg [28:0] RESULT_2000= 29'b0;
    reg [28:0] REAL_2000= 29'b0;
    reg [28:0] REAL_pos_2000= 29'b0;
    reg [28:0] REAL_neg_2000= 29'b0;
    reg [28:0] IMAG_2000= 29'b0;
    reg [28:0] IMAG_pos_2000= 29'b0;
    reg [28:0] IMAG_neg_2000= 29'b0;
    reg [8:0] angle_2000;   //0~360
    reg [8:0] angle_180_2000;
    reg [6:0] angle_90_2000;
    wire [12:0] SIN_value_2000;
    wire [12:0] COS_value_2000;
    reg [1:0] final_cal_2000 = 2'b00;
    
    reg [28:0] RESULT_3000= 29'b0;
    reg [28:0] REAL_3000= 29'b0;
    reg [28:0] REAL_pos_3000= 29'b0;
    reg [28:0] REAL_neg_3000= 29'b0;
    reg [28:0] IMAG_3000= 29'b0;
    reg [28:0] IMAG_pos_3000= 29'b0;
    reg [28:0] IMAG_neg_3000= 29'b0;
    reg [8:0] angle_3000;   //0~360
    reg [8:0] angle_180_3000;
    reg [6:0] angle_90_3000;
    wire [12:0] SIN_value_3000;
    wire [12:0] COS_value_3000;
    reg [1:0] final_cal_3000 = 2'b00;
    
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
    reg onecycle = 1'b0;
    always @(posedge MCLK) begin
        if (counter == 14'd9999) begin
        onecycle = 1'b1;
            if(onecycle == 1'b1) begin
                FREQ = (RESULT_1000>RESULT_2000 && RESULT_1000>RESULT_3000) ? 3'b001 : (RESULT_2000>RESULT_3000)? 3'b011:3'b111;
                counter <= 14'b00000000000000;
                onecycle <= 1'b0;
            end
        //reset counter value after the calculations are done
        end
        else begin
            counter <= counter + 1;    
            SAMPLE[counter] = mic_in;   //g(t)
            if(vart_1000==5'd20) begin
                    vart_1000<= 5'b00001;
                end
            else vart_1000 <= vart_1000 + 1'b1;
            if(vart_2000==5'd10) begin
                    vart_2000<= 5'b00001;
            end
            else vart_2000 <= vart_2000 + 1'b1;
            if(vart_3000==5'd7) begin
                    vart_3000<= 5'b00001;
            end
            else vart_3000 <= vart_3000 + 1'b1;
        end
        
    end
    
    /*
    Part 2: FFT formula inplementation
    for now we have three frequencies, 1000Hz, 2000Hz, 3000Hz,
    */
    
    // Section 1: 1000Hz
    FFT_sin sin_1000(angle_90_1000, SIN_value_1000);
    FFT_cos cos_1000(angle_90_1000, COS_value_1000);
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
            RESULT_1000 <= RESULT_1000 + IMAG_1000*IMAG_1000 + REAL_1000*REAL_1000;
            final_cal_1000 = final_cal_1000 + 1;
        end
        if (final_cal_1000 -- 2'b10) final_cal_1000 <= 2'b00;
    end

    // Section 2: 2000Hz
    FFT_sin sin_2000(angle_90_2000, SIN_value_2000);
    FFT_cos cos_2000(angle_90_2000, COS_value_2000);
    always @(posedge MCLK) begin
        //angle = (13'd6280 * vart_1000 / 15'd20000) * 9'd360 / 6.28;  // (0~6.28) need to improve the calculation
        angle_2000 = 19'd360000 * vart_2000; //(0~360)
        
        if (angle_2000 < 8'd180) begin   //final value is positive
            if (angle_2000 <= 7'd90) begin
                angle_90_2000 = angle_2000;
                IMAG_pos_2000 <=  IMAG_pos_2000 + mic_in * SIN_value_2000;
            end
            else begin
                angle_90_2000 = angle_2000 - 7'd90; //sin£¨¦Ð/2£«¦Á£©£½cos¦Á
                IMAG_pos_2000 <= IMAG_pos_2000 + mic_in * COS_value_2000;
            end
        end
        else begin //final value is negative  //sin£¨¦Ð£«¦Á£©£½£­sin¦Á
            angle_180_2000 = angle_2000 - 9'd180;
            if (angle_180_2000 <= 7'd90) begin
                angle_90_2000 = angle_2000;
                IMAG_neg_2000 <=  IMAG_neg_2000 + mic_in * SIN_value_2000;
            end
            else begin
                angle_90_2000 = angle_2000 - 7'd90; //sin£¨¦Ð/2£«¦Á£©£½cos¦Á
                IMAG_neg_2000 <= IMAG_neg_2000 + mic_in * COS_value_2000;
          end
        end
        
        if(vart_2000==5'd10) begin
            final_cal_2000 = final_cal_2000 + 1;
            REAL_2000 = REAL_pos_2000 - REAL_neg_2000;
            IMAG_2000 = IMAG_pos_2000 - IMAG_neg_2000;
        end
        if (final_cal_2000 == 2'b01) begin
            RESULT_2000 = IMAG_2000*IMAG_2000 + REAL_1000*REAL_2000;
            final_cal_2000 = final_cal_2000 + 1;
        end
        if (final_cal_2000 -- 2'b10) final_cal_2000 <= 2'b00;
    end
    
    // Section 3: 3000Hz
    FFT_sin sin_3000(angle_90_3000, SIN_value_3000);
    FFT_cos cos_3000(angle_90_3000, COS_value_3000);
    always @(posedge MCLK) begin
        //angle = (13'd6280 * vart_1000 / 15'd20000) * 9'd360 / 6.28;  // (0~6.28) need to improve the calculation
        angle_3000 = 19'd360000 * vart_3000; //(0~360)
        
        if (angle_3000 < 8'd180) begin   //final value is positive
            if (angle_3000 <= 7'd90) begin
                angle_90_3000 = angle_3000;
                IMAG_pos_3000 <=  IMAG_pos_3000 + mic_in * SIN_value_3000;
            end
            else begin
                angle_90_3000 = angle_3000 - 7'd90; //sin£¨¦Ð/2£«¦Á£©£½cos¦Á
                IMAG_pos_3000 <= IMAG_pos_3000 + mic_in * COS_value_3000;
            end
        end
        else begin //final value is negative  //sin£¨¦Ð£«¦Á£©£½£­sin¦Á
            angle_180_3000 = angle_3000 - 9'd180;
            if (angle_180_3000 <= 7'd90) begin
                angle_90_3000 = angle_3000;
                IMAG_neg_3000 <=  IMAG_neg_3000 + mic_in * SIN_value_3000;
            end
            else begin
                angle_90_3000 = angle_3000 - 7'd90; //sin£¨¦Ð/2£«¦Á£©£½cos¦Á
                IMAG_neg_3000 <= IMAG_neg_3000 + mic_in * COS_value_3000;
          end
        end
        
        if(vart_3000==5'd7) begin
            final_cal_3000 = final_cal_3000 + 1;
            REAL_3000 = REAL_pos_3000 - REAL_neg_3000;
            IMAG_3000 = IMAG_pos_3000 - IMAG_neg_3000;
        end
        if (final_cal_3000 == 2'b01) begin
            RESULT_3000 = IMAG_3000*IMAG_3000 + REAL_3000*REAL_3000;
            final_cal_3000 = final_cal_3000 + 1;
        end
        if (final_cal_3000 -- 2'b10) final_cal_3000 <= 2'b00;
    end
endmodule