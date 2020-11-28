/*  file:        Pipeline_cordic.v
    author:      Yi Zhan
    release:     14/02/2020
    brief: Pipeline cordic
*/

`define XY_BITS    9
`define THETA_BITS 8
`define ITERATIONS 8
`define ITERATION_BITS 3


//The main computing module. And also main data flow
module Main_CORDIC_rotation_unit(
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
  (*mark_debug="true"*)wire signed [`XY_BITS:0] x_i_shifted;
  (*mark_debug="true"*)wire signed [`XY_BITS:0] y_i_shifted;
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
        4'b00000: begin x_scalling <= x_rotation+sshift(x_rotation,3)+sshift(x_rotation,6)+sshift(x_rotation,7); 
                        y_scalling <= y_rotation+sshift(y_rotation,3)+sshift(y_rotation,6)+sshift(y_rotation,7);end	//  1  0 -1  0  0 -1  0 -1 -1  0  0  0  0  0  1 
        4'b00001: begin x_scalling <= x_rotation+sshift(x_rotation,5); 
                        y_scalling <= y_rotation+sshift(y_rotation,5); end 	//  1  0  0 -1  0  0  1  0  1  0  0  0  0 -1  0  1 
        4'b00010: begin x_scalling <= x_rotation+sshift(x_rotation,7); 
                        y_scalling <= y_rotation+sshift(y_rotation,7); end     		//  1  0  0  0  0 -1  0  0  0  0  1  1  0  0 -1
                          //  1    								//  1  0  0  0  0  0  0  0  0  0  0  0  0 -1 
        default: begin  x_scalling <= x_rotation;
                        y_scalling <= y_rotation; end
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
module Pipeline_CORDIC_exp_8_V2(
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
    input [`ITERATIONS:0] i;
    begin
      case (i)
      4'd00: tanangle = 9'd70;   //  1/1
      4'd01: tanangle = 9'd32;   //  1/2
      4'd02: tanangle = 9'd16;     //  1/4
      4'd03: tanangle = 9'd8;     //  1/8
      4'd04: tanangle = 9'd4;     //  1/16
      4'd05: tanangle = 9'd2;     //  1/32
      4'd06: tanangle = 9'd1;      //  1/64
      4'd07: tanangle = 9'd0;      //  1/128
      default:tanangle = 9'd0;
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
                if (z_abs >= 9'd70)
                  begin iteration <= 00; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd51) && (z_abs < 9'd70))
                  begin iteration <= 00; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 9'd32) && (z_abs < 9'd51))
                  begin iteration <= 01; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd24) && (z_abs < 9'd32))
                  begin iteration <= 01; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 9'd16) && (z_abs < 9'd24))
                  begin iteration <= 02; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd12) && (z_abs < 9'd16))
                  begin iteration <= 02; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 9'd8) && (z_abs < 9'd12))
                  begin iteration <= 03; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd6) && (z_abs < 9'd8))
                  begin iteration <= 03; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 9'd4) && (z_abs < 9'd6))
                  begin iteration <= 04; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd3) && (z_abs < 9'd4))
                  begin iteration <= 04; sign_bit_next <= ~z[`THETA_BITS]; end else
                if ((z_abs >= 9'd2) && (z_abs < 9'd3))
                  begin iteration <= 05; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd1) && (z_abs < 9'd2))
                  begin iteration <= 06; sign_bit_next <= z[`THETA_BITS]; end else
                if ((z_abs >= 9'd0) && (z_abs < 9'd1))
                  begin iteration <= 06; sign_bit_next <= ~z[`THETA_BITS]; end else
                if (z_abs == 9'h1ff)
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

  
  
  Main_CORDIC_rotation_unit U (clk,rst,init,iteration,sign_bit,tangle,x,y,z,x_o,y_o,z_o);

endmodule
