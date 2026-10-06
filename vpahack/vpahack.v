`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:09:53 10/02/2026 
// Design Name: 
// Module Name:    vpahack 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vpahack(
	input CLK8,
	input FC0,
	input FC1,
	input VPA_MB,
	input E,
	output VMA,
	output DTACK,
	input RW,
	input AS,
	output VPA_OUT,
	output LED2,
	output LED3,
	output LED4,
	output LED5
 );

	wire IACK = FC0 && FC1 && !AS && RW;
//	wire IACK = !AS && RW;

	wire ACIA = !VPA_MB && !FC1 && FC0;

	wire [2:0] acia_dtack;
	FDCP ff_acia_dtack1( .D( ACIA ), .C( E ), .CLR( AS ), .PRE( 1'b0 ), .Q( acia_dtack[0]) );
	FDCP ff_acia_dtack2( .D( acia_dtack[0] ), .C( E ), .CLR( AS ), .PRE( 1'b0 ), .Q( acia_dtack[1]) );
	FDCP ff_acia_dtack3( .D( acia_dtack[1] ), .C( E ), .CLR( AS ), .PRE( 1'b0 ), .Q( acia_dtack[2]) );

	
	assign VPA_OUT = ( FC0 & FC1 ) ? VPA_MB : 1'b1;
	assign VMA = acia_dtack[0] ? 1'b0 : 1'bz;
	assign DTACK = acia_dtack[1] ? 1'b0 : 1'bz; 

	assign LED5 = ~FC1;	
	assign LED4 = RW;
	assign LED3 = AS;
	assign LED2 = ~VPA_MB;
endmodule
