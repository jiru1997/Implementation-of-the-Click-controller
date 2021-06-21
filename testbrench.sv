`timescale 1ns/1ps
//-----------------------------------------------------------------------------------------
module tb;

  parameter ff_width = 1;
  parameter WIDTH = 12;
  reg reset;
  reg [3 : 0] random_delay_time;
  wire [ff_width - 1 : 0] copyToDg;
  wire [ff_width - 1 : 0] DgToCopy;
  wire [WIDTH - 1 : 0] current_data;

  wire [ff_width - 1 : 0] upperToCp;
  wire [ff_width - 1 : 0] lowerToCp;
  wire [ff_width - 1 : 0] copyToFork;
  wire [WIDTH - 1 : 0] dataFromCp;

  wire [ff_width - 1 : 0] subToFork;
  wire [ff_width - 1 : 0] upperToSub;
  wire [WIDTH - 1 : 0] dataFromUpper;

  wire [ff_width - 1 : 0] lowerToSub;
  wire [WIDTH - 1 : 0] dataFromLower;

  wire [ff_width - 1 : 0] dbToSub;
  wire [ff_width - 1 : 0] subToDb;
  wire [WIDTH - 1 : 0] dataFromSb;
  wire [WIDTH - 1 : 0] finalResult;

  data_generator dg (reset, copyToDg, DgToCopy, current_data);
  copy cp (DgToCopy, current_data, reset, upperToCp, lowerToCp, copyToDg, copyToFork, dataFromCp);
  upperbranch ub (dataFromCp, reset, copyToFork, subToFork, upperToCp, upperToSub, dataFromUpper);
  lowerbranch lb (dataFromCp, reset, copyToFork, subToFork, lowerToCp, lowerToSub, dataFromLower);
  subtractor sb (upperToSub, lowerToSub, dataFromUpper, dataFromLower, dbToSub, reset, subToDb, dataFromSb, subToFork, random_delay_time);
  data_bucket db (dataFromSb, reset, subToDb, dbToSub, finalResult);

  initial begin
    reset <= 1;
    random_delay_time <= {$random()} % (2**3) + 1; 

    #2 reset = ~reset;
    #4 reset = ~reset;
    #100;
    $stop();
  end
endmodule 