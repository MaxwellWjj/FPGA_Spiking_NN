
`define VALUEIN     8
`define VALUEOUT    9
`define VALUEOUT_2  18
`define ITERATIONS     8
`define CNTITERATION_BITS 3

//The main computing module.
module M_H_CORDIC_exp_8_shift(
    input clk,
    input rst,
    input init,
    input signed [`VALUEIN : 0] value_in,    //x
    output reg signed [`VALUEOUT : 0] value_out, //exp(x)
    output reg done
    );

    reg [`CNTITERATION_BITS : 0] cnt_iterations;   //n
    reg [`VALUEOUT : 0] mul_result;
    reg [`VALUEOUT_2: 0] mul_tmp;
    reg  [`VALUEOUT : 0] value_reg;
    //reg  [`VALUEIN : 0] list_reg;
    reg signed [`VALUEIN : 0] z;
    wire signed [`VALUEIN : 0] z_abs;
    reg [`VALUEIN : 0] poweroftwo;


    //This function is used to realize signed shift
    function [`VALUEOUT_2:0] sshift;
    input signed [`VALUEOUT:0] D;
    input [`CNTITERATION_BITS:0] i;
      begin 
        sshift = ({{`ITERATIONS{D[`VALUEOUT]}},D,{8{1'b0}}} >> i) | (D[`VALUEOUT] << `VALUEOUT_2);
      end
    endfunction



    always@(posedge clk) 
        begin
            if(rst) 
                begin
                    cnt_iterations <= 0;
                    value_reg <= 9'b010000000;
                    value_out <= 0;
                    //list_reg <= 9'b010000000; // 1
                    z <= 0;
                    poweroftwo <= 8'b01000000; 
                    done<=0;
                end
            else if(init) 
                begin
                    z <= value_in;
                    value_reg <= 9'b010000000;  // 1
                    cnt_iterations <= 0;
                    poweroftwo <= 8'b01000000;  // 0.5
                end
            else
                begin
                    if(cnt_iterations == 4'd8) 
                        begin
                            cnt_iterations <= 0;
                            done <= 1;
                            value_out <= mul_result;
                    
                        end
                    else 
                        begin              
                            if(poweroftwo < z_abs)
                                begin
                                    cnt_iterations <= cnt_iterations + 1;
                                    if (value_in[`VALUEIN])
                                        begin
                                            z <= z + poweroftwo;
                                        end
                                    else
                                        begin
                                            z <= z - poweroftwo;
                                        end
                                    value_reg <= mul_result;
                                    poweroftwo <= poweroftwo >> 1;
                                    done <= 0;
                                end
                            else
                                begin
                                    poweroftwo <= poweroftwo >> 1;
                                    cnt_iterations <= cnt_iterations + 1;
                                    done <= 0;
                                end
                        end
                end
        end

    always @ (posedge clk)
        begin
            //mul_tmp = multiplication(value_reg,cnt_iterations);
            if (value_in[`VALUEIN])
                begin
                    case (cnt_iterations)
                        4'd00: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,4)+sshift(value_reg,5)+sshift(value_reg,7);//+sshift(value_reg,8);    //value_reg*e^(-1/2)
                        4'd01: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,6)+sshift(value_reg,7);//+sshift(value_reg,8);    //value_reg*e^(-1/4)
                        4'd02: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,3);//+sshift(value_reg,8);    //value_reg*e^(-1/8)
                        4'd03: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,3)+sshift(value_reg,4);    //value_reg*e^(-1/16)
                        4'd04: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,3)+sshift(value_reg,4)+sshift(value_reg,5);    //value_reg*e^(-1/32)
                        4'd05: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,3)+sshift(value_reg,4)+sshift(value_reg,5)+sshift(value_reg,6);    //value_reg*e^(-1/64)
                        4'd06: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,3)+sshift(value_reg,4)+sshift(value_reg,5)+sshift(value_reg,6)+sshift(value_reg,7);    //value_reg*e^(-1/128)
                        4'd07: mul_tmp <= sshift(value_reg,1)+sshift(value_reg,2)+sshift(value_reg,3)+sshift(value_reg,4)+sshift(value_reg,5)+sshift(value_reg,6)+sshift(value_reg,7);//+sshift(value_reg,8);    //value_reg*e^(-1/256)
                        default: 
                            begin
                                mul_tmp <= sshift(value_reg,0);
                            end
                    endcase
                end
            else
                begin
                    case (cnt_iterations)
                        4'd00: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,1)+sshift(value_reg,3)+sshift(value_reg,6)+sshift(value_reg,7);    //value_reg*e^(1/2)
                        4'd01: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,2)+sshift(value_reg,5);  //value_reg*e^(1/4)
                        4'd02: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,3)+sshift(value_reg,7);   //value_reg*e^(1/8)
                        4'd03: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,4);   //value_reg*e^(1/16)
                        4'd04: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,5);   //value_reg*e^(1/32)
                        4'd05: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,6);   //value_reg*e^(1/64)
                        4'd06: mul_tmp <= sshift(value_reg,0)+sshift(value_reg,7);   //value_reg*e^(1/128)
                        4'd07: mul_tmp <= sshift(value_reg,0);//+sshift(value_reg,8);   //value_reg*e^(1/256)
                        default:
                        begin
                            mul_tmp <= sshift(value_reg,0);
                        end
                    endcase
                end
            mul_result <= mul_tmp[`VALUEOUT_2:`VALUEIN];
        end
    
    assign z_abs = z[`VALUEIN]? ~z+1'b1:z;

endmodule
