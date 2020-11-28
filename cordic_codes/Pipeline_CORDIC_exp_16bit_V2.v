/*  file:        Pipeline_cordic.v
    author:      Yi Zhan
    release:     14/02/2020
    brief: Pipeline cordic
*/

`define XY_BITS    17
`define THETA_BITS 16
`define ITERATIONS 16
`define ITERATION_BITS 4


//The main computing module. And also main data flow
module Main_CORDIC_rotation_unit_16(
  input wire clk,
  input wire rst,
  input wire init,
  input wire [`ITERATION_BITS:0] iteration,
  input wire sign_bit,
  input wire signed [`THETA_BITS:0] tangle,
  input wire signed  [`XY_BITS:0]    x_i,
  input wire signed  [`XY_BITS:0]    y_i,
  input wire signed  [`THETA_BITS:0] z_i,
  output wire signed [`XY_BITS:0]    x_o,
  output wire signed [`XY_BITS:0]    y_o,
  output wire signed [`THETA_BITS:0] z_o
);

  //5 registers
  reg [`XY_BITS:0]    x_rotation;
  reg [`XY_BITS:0]    y_rotation;
  reg [`XY_BITS:0]    x_scalling;
  reg [`XY_BITS:0]    y_scalling;
  reg signed [`THETA_BITS:0] z_s;
  wire signed [`XY_BITS:0] x_i_shifted;
  wire signed [`XY_BITS:0] y_i_shifted;
  reg [`ITERATION_BITS:0] iteration_last;
  reg en;

  always @ (posedge clk or posedge rst)
    begin
      if (rst)
        en <=0;
      else
        en <= ~en;
    end
  //This function is used to shift
  function [`XY_BITS:0] sshift;
    input signed [`XY_BITS:0] D;
    input [`ITERATION_BITS:0] i;
      begin 
        sshift = ({{`ITERATIONS{D[`XY_BITS]}},D} >> i) | (D[`XY_BITS] << `XY_BITS);
      end
  endfunction

  assign x_i_shifted = sshift(x_i,iteration+1);
  assign y_i_shifted = sshift(y_i,iteration+1);
//  assign x_i_shifted = x_i >>> (iteration + 1);
//  assign y_i_shifted = y_i >>> (iteration + 1);

  //Rotation and update
  always @ (negedge en)
    begin
      if (rst)
        begin
          x_rotation <= 0;
          y_rotation <= 0;
          z_s <= 0;
        end
      else
        begin
          if (init)
            begin
              x_rotation <= x_i;
              y_rotation <= y_i;
              z_s <= z_i;
            end
          else
            if (z_i == 0)
              begin
                x_rotation <= x_i;
                y_rotation <= y_i;
                z_s <= z_i;
              end
          else
            if (sign_bit)
              begin
                x_rotation <= x_i - y_i_shifted;
                y_rotation <= y_i - x_i_shifted;
                z_s <= z_i + tangle;
              end
          else
            if (~sign_bit)
              begin
                x_rotation <= x_i + y_i_shifted;
                y_rotation <= y_i + x_i_shifted;
                z_s <= z_i - tangle;
              end
        end
    end

//  always @ (posedge clk)
//    begin
//        iteration_last <= iteration;
//    end

  //Scalling 
  always @ (posedge clk)
    begin
      case (iteration)                                                                                            //  0 -1 -2 -3 -4 -5 -6 -7 -8 -9-10-11-12-13-14-15 
        5'b00000: begin x_scalling = x_rotation+sshift(x_rotation,3)+sshift(x_rotation,5)-sshift(x_rotation,9)+sshift(x_rotation,12)+sshift(x_rotation,13)+sshift(x_rotation,15); 
		                    y_scalling = y_rotation+sshift(y_rotation,3)+sshift(y_rotation,5)-sshift(y_rotation,9)+sshift(y_rotation,12)+sshift(y_rotation,13)+sshift(y_rotation,15); end	//  1  0 -1  0  0 -1  0 -1 -1  0  0  0  0  0  1 
        5'b00001: begin x_scalling = x_rotation+sshift(x_rotation,5)+sshift(x_rotation,10)+sshift(x_rotation,11)+sshift(x_rotation,14); 
                        y_scalling = y_rotation+sshift(y_rotation,5)+sshift(y_rotation,10)+sshift(y_rotation,11)+sshift(y_rotation,14); end 	//  1  0  0 -1  0  0  1  0  1  0  0  0  0 -1  0  1 
        5'b00010: begin x_scalling = x_rotation+sshift(x_rotation,7)+sshift(x_rotation,14)+sshift(x_rotation,15); 
                        y_scalling = y_rotation+sshift(y_rotation,7)+sshift(y_rotation,14)+sshift(y_rotation,15); end     		//  1  0  0  0  0 -1  0  0  0  0  1  1  0  0 -1
        5'b00011: begin x_scalling = x_rotation+sshift(x_rotation,9); 
                        y_scalling = y_rotation+sshift(y_rotation,9); end			     		//  1  0  0  0  0  0  0 -1  0  0  0  0  0  0  1  1
        5'b00100: begin x_scalling = x_rotation+sshift(x_rotation,11); 
                        y_scalling = y_rotation+sshift(y_rotation,11); end    								//  1  0  0  0  0  0  0  0  0 -1
        5'b00101: begin x_scalling = x_rotation+sshift(x_rotation,13); 
                        y_scalling = y_rotation+sshift(y_rotation,13); end     								//  1  0  0  0  0  0  0  0  0  0  0 -1 
        5'b00110: begin x_scalling = x_rotation+sshift(x_rotation,15);
                        y_scalling = y_rotation+sshift(y_rotation,15); end    								//  1  0  0  0  0  0  0  0  0  0  0  0  0 -1 
        default: begin  x_scalling = x_rotation;
                        y_scalling = y_rotation; end
      endcase
    end

//  always @ (posedge clk)
//    begin
//      case (iteration)                                                                                            //  0 -1 -2 -3 -4 -5 -6 -7 -8 -9-10-11-12-13-14-15 
//        4'b00000: begin x_scalling <= x_rotation+(x_rotation>>>3)+(x_rotation>>>6)+(x_rotation>>>7); 
//                        y_scalling <= y_rotation+(y_rotation>>>3)+(y_rotation>>>6)+(y_rotation>>>7);end	//  1  0 -1  0  0 -1  0 -1 -1  0  0  0  0  0  1 
//        4'b00001: begin x_scalling <= x_rotation+(x_rotation>>>5); 
//                        y_scalling <= y_rotation+(y_rotation>>>5); end 	//  1  0  0 -1  0  0  1  0  1  0  0  0  0 -1  0  1 
//        4'b00010: begin x_scalling <= x_rotation+(x_rotation>>>7); 
//                        y_scalling <= y_rotation+(y_rotation>>>7); end     		//  1  0  0  0  0 -1  0  0  0  0  1  1  0  0 -1
//                          //  1    								//  1  0  0  0  0  0  0  0  0  0  0  0  0 -1 
//        default: begin  x_scalling <= x_rotation;
//                        y_scalling <= y_rotation; end
//      endcase
//    end

  assign x_o = x_scalling;
  assign y_o = y_scalling;
  assign z_o = z_s;
endmodule



//The control module, and the Angle select operation
module Pipeline_CORDIC_exp_16_V2(
  input wire clk,
  input wire rst,
  input wire init,
  input wire signed [`XY_BITS:0]    x_i,
  input wire signed [`XY_BITS:0]    y_i,
  input wire signed [`THETA_BITS:0] z_i,
  output wire signed [`XY_BITS:0]    x_o,
  output wire signed [`XY_BITS:0]    y_o,
  output wire signed [`THETA_BITS:0] z_o,
  output wire signed [`XY_BITS:0]    exp_o, 
  output reg done
);


  //Look up table of residual angle bands
 function [`THETA_BITS:0] tanangle;
    input [`ITERATION_BITS:0] i;
    begin
      case (i)
      5'd00: tanangle = 17'd17999;   //  1/1
      5'd01: tanangle = 17'd8369;   //  1/2
      5'd02: tanangle = 17'd4117;     //  1/4
      5'd03: tanangle = 17'd2050;     //  1/8
      5'd04: tanangle = 17'd1024;     //  1/16
      5'd05: tanangle = 17'd512;     //  1/32
      5'd06: tanangle = 17'd256;      //  1/64
      5'd07: tanangle = 17'd128;      //  1/128
      5'd08: tanangle = 17'd64;      //  1/256
      5'd09: tanangle = 17'd32;       //  1/512
      5'd10: tanangle = 17'd16;       //  1/1024
      5'd11: tanangle = 17'd8;       //  1/2048
      5'd12: tanangle = 17'd4;        //  1/4096
      5'd13: tanangle = 17'd2;        //  1/8192
      5'd14: tanangle = 17'd1;        //  1/16k
      5'd15: tanangle = 17'd0;        //  1/32k
      endcase
    end
  endfunction



  //4 registers
  reg [`ITERATION_BITS:0] iteration;//the number of selected angle
  reg sign_bit;
  reg sign_bit_next;//these are di
  wire signed [`THETA_BITS:0] tangle;//the selected angle
  reg signed [`THETA_BITS:0] z_abs;
  reg en;
  
  wire signed [`XY_BITS:0] x,y;
  wire signed [`THETA_BITS:0] z;
  assign x = init ? x_i : x_o;
  assign y = init ? y_i : y_o;
  assign z = init ? z_i : z_o;
  assign exp_o = x_o + y_o;

  always @ (posedge clk or posedge rst)
    begin
      if (rst)
        en <=0;
      else
        en <= ~en;
    end

  always @ (posedge en)
  begin
    if (rst) 
      sign_bit <= 1;
    else if (init)
      sign_bit <= 1;
    else
      sign_bit <= sign_bit_next;
  end 

  always @ (posedge en)
    begin
        if (rst)
            begin
                sign_bit_next <=1;
                iteration <= 06;
            end
        else if (init)
            begin
                sign_bit_next <=1;
                iteration <= 06;
            end
        else  
            begin
              z_abs = z[`THETA_BITS]? ~z+1'b1:z;
                if (z_abs >= 17'd17999)
                  begin iteration <= 00; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd13184) && (z_abs < 17'd17999))
                  begin iteration <= 00; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd8369) && (z_abs < 17'd13184))
                  begin iteration <= 01; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd6243) && (z_abs < 17'd8369))
                  begin iteration <= 01; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd4117) && (z_abs < 17'd6243))
                  begin iteration <= 02; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd3083) && (z_abs < 17'd4117))
                  begin iteration <= 02; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd2050) && (z_abs < 17'd3083))
                  begin iteration <= 03; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd1537) && (z_abs < 17'd2050))
                  begin iteration <= 03; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd1024) && (z_abs < 17'd1537))
                  begin iteration <= 04; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd768) && (z_abs < 17'd1024))
                  begin iteration <= 04; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd512) && (z_abs < 17'd768))
                  begin iteration <= 05; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd384) && (z_abs < 17'd512))
                  begin iteration <= 06; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd256) && (z_abs < 17'd384))
                  begin iteration <= 06; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd192) && (z_abs < 17'd256))
                  begin iteration <= 00; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd128) && (z_abs < 17'd192))
                  begin iteration <= 01; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd96) && (z_abs < 17'd128))
                  begin iteration <= 01; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd64) && (z_abs < 17'd96))
                  begin iteration <= 02; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd48) && (z_abs < 17'd64))
                  begin iteration <= 02; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd32) && (z_abs < 17'd48))
                  begin iteration <= 03; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd24) && (z_abs < 17'd32))
                  begin iteration <= 03; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd16) && (z_abs < 17'd24))
                  begin iteration <= 04; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd12) && (z_abs < 17'd16))
                  begin iteration <= 04; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd8) && (z_abs < 17'd12))
                  begin iteration <= 05; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd6) && (z_abs < 17'd8))
                  begin iteration <= 06; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd4) && (z_abs < 17'd6))
                  begin iteration <= 06; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd3) && (z_abs < 17'd4))
                  begin iteration <= 04; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd2) && (z_abs < 17'd3))
                  begin iteration <= 05; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 17'd1) && (z_abs < 17'd2))
                  begin iteration <= 06; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 17'd0) && (z_abs < 17'd1))
                  begin iteration <= 06; sign_bit_next <= z[`THETA_BITS]; end else
                if (z == 17'h1ffff)
                  begin iteration <= 06; sign_bit_next <= 1; end
                else
                  begin iteration <= 06; sign_bit_next <= 0; end
            end
    end
    
  assign tangle = tanangle(iteration);

  //generate the done
  always @ (posedge clk or posedge init)
    begin
      if (init) done <= 0;
      else if (rst) done <= 0;
      else if (z == 0) done <=1;
  end

  
  
  Main_CORDIC_rotation_unit_16 U (clk,rst,init,iteration,sign_bit,tangle,x,y,z,x_o,y_o,z_o);

endmodule
