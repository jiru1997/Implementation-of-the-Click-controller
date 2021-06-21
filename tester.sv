`timescale 1ns/1ps
module tester;
  parameter ff_width = 1;
  reg reset;
  reg aReq;
  reg bAck;
  wire [ff_width - 1 : 0] aAck;
  wire [ff_width - 1 : 0] bReq;
  wire clk;

  clickcontrol cl (reset, aReq, bAck, aAck, bReq, clk);

  initial begin
    aReq = 0;
    bAck = 0;
    reset = 1;

    #5 aReq <= 1;
    #20 aReq <= 0;
    #5 reset = ~ reset;
    #5 reset = ~ reset;

    #5 aReq <= 1;
    #20 aReq <= 0;
    bAck <= 1;
    #20 bAck <= 0;

    #5 aReq <= 1;
    #20 aReq <= 0;
    bAck <= 1;
    #20 bAck <= 0;

    #10;
    $stop();
  end

endmodule

