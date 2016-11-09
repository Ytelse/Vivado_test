`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2015 02:52:16 PM
// Design Name: 
// Module Name: sw_led
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


module sw_btn_led(
    input [3:0]sw,
    input [3:0]btn,
    output [3:0]led
    );
    
    assign led = sw | btn;
    
endmodule
