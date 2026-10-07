`timescale 1ns / 1ps

// main_top.v - Main module for the system

module main_top (
	input CLK8,

	input BG_I,
	input BG_MB,

	input RESET_I,
	input RESET_MB,
	input AS,

	inout BR_MB,
	inout BGACK_MB,
	inout HALT_MB,

	output CLK8_O,
	output HALT_I,
	output BR_I,
	output BGACK_I,
	
	
	input FC0,
	input FC1,
	input E,
	input VPA_MB,
	output VMA_MB,
	output DTACK,
	output VPA_EXT
);

	reg [3:0] state = 4'd0;

	reg halt_i_int = 1'b0;
	reg halt_mb_int = 1'b0;
	reg br_i_int = 1'b0;
	reg br_mb_int = 1'b1;
	reg bgack_i_int = 1'b0;
	reg bgack_mb_int = 1'b1;


	reg [3:0] BR_MB_D; // delay for BR_MB so we wait a certain amount of time before trying to reclaim bus
	always @( posedge CLK8 ) begin
		if( !BR_MB )
			BR_MB_D <= 'b1111;
		else
			BR_MB_D <= { BR_MB_D[2:0], 1'b1 };
	end


	always @(posedge CLK8 or negedge RESET_MB) begin  
		if( !RESET_MB ) begin
			halt_i_int <= 1'b1;
			halt_mb_int <= 1'b1;
			br_i_int <= 1'b0;
			br_mb_int <= 1'b1;
			bgack_i_int <= 1'b0;
			bgack_mb_int <= 1'b1;

			state <= 'd0; // Reset state
		end
		else begin
			case(state)
			  4'd0: begin // BUS NOT OURS
					halt_mb_int <= 1'b0;
					br_mb_int <= 1'b1;
					bgack_mb_int <= 1'b1;

					br_i_int <= 1'b0;
					bgack_i_int <= 1'b0;
					halt_i_int <= 1'b0;

					if( // BR_MB
					( BR_MB_D[1] ) && BGACK_MB && BG_MB ) begin
						state <= 4'd1; // If no bus arb in play for a number of counts
					end
			  end
			
			  4'd1: begin // START REQUEST, WAIT BG
				 halt_mb_int <= 1'b0;
				 br_mb_int <= 1'b0;
				 bgack_mb_int <= 1'b1;

				 br_i_int <= 1'b0;
				 bgack_i_int <= 1'b0;
					halt_i_int <= 1'b0;

				 if( !BG_MB && BGACK_MB && AS ) begin
					state <= 4'd2; // If bus grant, move to accept state
					br_mb_int <= 1'b1;
					bgack_mb_int <= 1'b0;
				 end
			  end
			  4'd2: begin // BUS IS MINE, DEAD CYCLE
					halt_mb_int <= 1'b0;
					br_mb_int <= 1'b1;
					bgack_mb_int <= 1'b0;

					br_i_int <= 1'b1;
					bgack_i_int <= 1'b1;
					halt_i_int <= 1'b0;

					state <= 'd3;
			  end		  
			  4'd3: begin // BUS IS MINE, DEAD CYCLE
					halt_mb_int <= 1'b0;
					br_mb_int <= 1'b1;
					bgack_mb_int <= 1'b0;

					br_i_int <= 1'b1;
					bgack_i_int <= 1'b1;
					halt_i_int <= 1'b0;

					state <= 'd4;
			  end	
			  4'd4: begin // BUS IS MINE, AWAIT BGI
					halt_mb_int <= 1'b0;
					br_i_int <= 1'b1;
					br_mb_int <= 1'b1;

					bgack_i_int <= 1'b1;
					bgack_mb_int <= 1'b0;
					halt_i_int <= 1'b1;

					if( AS && !BG_I ) begin
						state <= 'd5;
						bgack_mb_int <= 1'b1;
						bgack_i_int <= 1'b0;
						halt_i_int <= 1'b0;
					end
			  end					  
			  4'd5: begin // RELINQUISH, AWAIT BG_MB
					halt_mb_int <= 1'b0;
					br_mb_int <= 1'b1;
					bgack_mb_int <= 1'b1;

					br_i_int <= 1'b0;
					bgack_i_int <= 1'b0;
					halt_i_int <= 1'b0;

					if( !BG_MB || ( BR_MB && BG_MB && BGACK_MB ) ) begin
						state <= 4'd0; // Back to initial state
					end
			  end
			endcase
		end
	end

	assign CLK8_O = ~CLK8;

//	assign HALT_I = RESET_MB ? ( state == 'd4 ? 1'bz : 1'b0 ) : HALT_MB;
	assign HALT_I = RESET_MB ? halt_i_int : HALT_MB;
	assign HALT_MB = ( !RESET_MB || halt_mb_int ? 1'bz : 1'b0 );
//	assign BR_I = (state == 'd4) ? BR_MB : 1'b1;
	assign BR_I = br_i_int ? BR_MB : 1'b0;
	assign BR_MB = br_mb_int ? 1'bz : 1'b0;
	assign BGACK_I = bgack_i_int ;// ? 1'bz : 1'b0;
	assign BGACK_MB = bgack_mb_int ? 1'bz : 1'b0;

// VPA hack section

//	wire IACK = FC0 && FC1 && !AS;
	wire ACIA = !VPA_MB && !(FC1 && FC0);

	wire [2:0] acia_dtack;
	FDCP ff_acia_dtack1( .D( ACIA ), .C( ~E ), .CLR( AS ), .PRE( 1'b0 ), .Q( acia_dtack[0]) ); // Processor asserts when E goes low after receiving VPA.
																																	// Accessory waits for E to go high then presents data
	FDCP ff_acia_dtack2( .D( acia_dtack[0] ), .C( ~E ), .CLR( AS ), .PRE( 1'b0 ), .Q( acia_dtack[1]) ); // Processor drives E low and negates AS etc, latching on the edge
	FDCP ff_acia_dtack3( .D( acia_dtack[1] ), .C( ~E ), .CLR( AS ), .PRE( 1'b0 ), .Q( acia_dtack[2]) ); // not used
	
	assign VPA_EXT = ( FC0 & FC1 ) ? VPA_MB : 1'b1;
	assign VMA_MB = acia_dtack[0] ? 1'b0 : 1'bz;
	assign DTACK = acia_dtack[1] ? 1'b0 : 1'bz; 


endmodule
