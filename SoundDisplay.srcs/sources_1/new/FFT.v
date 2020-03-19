`timescale 1ns / 1ps


module fftt;
    // Inputs
    reg start;
    reg fwd_inv;
    reg CLK100MHZ;
    reg scale_sch_we;
    reg fwd_inv_we;
    reg [7:0] scale_sch;
    wire rfd;
    wire [3:0] xn_index;
    reg [15:0] xn_re;
    reg [15:0] xn_im;

    // Outputs
    wire done;
    wire busy;
    wire edone;
    wire ovflo;
    wire dv;
    wire [3:0] xk_index;
    wire [15:0] xk_im;
    wire [15:0] xk_re;

    // Instantiate the Unit Under Test (UUT)

    fftuut (

           .rfd(rfd),
           
           .start(start),

           .fwd_inv(fwd_inv),

           .dv(dv),

           .done(done),

           .CLK100MHZ(CLK100MHZ),

           .busy(busy),

           .scale_sch_we(scale_sch_we),

           .fwd_inv_we(fwd_inv_we),

           .edone(edone),

           .ovflo(ovflo),

           .xn_re(xn_re),

           .xk_im(xk_im),

           .xn_index(xn_index),

           .scale_sch(scale_sch),

           .xk_re(xk_re),

           .xn_im(xn_im),

           .xk_index(xk_index)

    );

 

    initial begin
           // Initialize Inputs
           start = 1;
           fwd_inv = 1;
           CLK100MHZ = 0;
           scale_sch_we =1;
           scale_sch = 8'b01010101;
           fwd_inv_we = 1;
           xn_re = 0;           
           xn_im = 0;
           num= 0;

           // Wait 100 ns for global reset tofinish
           #100;   
    end

always begin

      #10 CLK100MHZ<= 1;
           #10 CLK100MHZ<= 0;
    end

reg[3:0]num;

always@(posedge CLK100MHZ) begin

    if(rfd) begin

           num<= num + 1'b1;
           case(num)
                  4'd0: xn_re<= 10000;
                  4'd1:xn_re<= 10000;
                  4'd2:xn_re<= 10000;
                  4'd3:xn_re<= 10000;
                  4'd4:xn_re<= 10000;
                  4'd5:xn_re<= 10000;
                                       4'd6:xn_re<= 10000;
                                       4'd7:xn_re<= 0;
                                       4'd8:xn_re<= 0;
                                       4'd9:xn_re<= 0;
                                       4'd10:xn_re<= 0;
                                       4'd11:xn_re<= 0;
                                       4'd12:xn_re<= 0;
                                       4'd13:xn_re<= 0;
                                       4'd14:xn_re<= 0;
                                       4'd15: xn_re<=10000;
                                default: ;
                         endcase

    end

end

endmodule

