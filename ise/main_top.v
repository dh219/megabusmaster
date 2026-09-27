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
  output BGACK_I
);

	reg [3:0] state = 4'd0;

	reg halt_mb_int = 1'bz;
	reg br_i_int = 1'bz;
	reg br_mb_int = 1'b1;
	reg bgack_i_int = 1'bz;
	reg bgack_mb_int = 1'b1;


	reg [7:0] BR_MB_CNT; // delay for BR_MB so we wait a certain amount of time before trying to reclaim bus
	always @( posedge CLK8 ) begin
		if( !BR_MB )
			BR_MB_CNT <= 'd0;
		else
			BR_MB_CNT <= BR_MB_CNT + 'd1;
	end


	always @(posedge CLK8 or negedge RESET_MB) begin  
		if( !RESET_MB ) begin
			halt_mb_int <= 1'bz;
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
				 br_i_int <= 1'b0;
				 br_mb_int <= 1'b1;
				 bgack_i_int <= 1'b0;
				 bgack_mb_int <= 1'b1;

				 if( // BR_MB
				 ( BR_MB_CNT[7] ) && BGACK_MB && BG_MB ) begin
					state <= 4'd1; // If no bus arb in play for a number of counts
				 end
			  end
			
			  4'd1: begin // START REQUEST, WAIT BG
				 halt_mb_int <= 1'b0;
				 br_i_int <= 1'b0;
				 br_mb_int <= 1'b0;
				 bgack_i_int <= 1'b0;
				 bgack_mb_int <= 1'b1;

				 if( !BG_MB && BGACK_MB && AS ) begin
					state <= 4'd2; // If bus grant, move to accept state
					br_mb_int <= 1'b1;
					bgack_mb_int <= 1'b0;

				 end
			  end
			  4'd2: begin // BUS IS MINE, DEAD CYCLE
					halt_mb_int <= 1'b0;
					br_i_int <= 1'b1;
					br_mb_int <= 1'b1;
					bgack_i_int <= 1'b1;
					bgack_mb_int <= 1'b0;

					state <= 'd3;
			  end		  
			  4'd3: begin // BUS IS MINE, DEAD CYCLE
					halt_mb_int <= 1'b0;
					br_i_int <= 1'b1;
					br_mb_int <= 1'b1;
					bgack_i_int <= 1'b1;
					bgack_mb_int <= 1'b0;

					state <= 'd4;
			  end	
			  4'd4: begin // BUS IS MINE, AWAIT BGI
				 halt_mb_int <= 1'b0;
				 br_i_int <= 1'b1;
				 br_mb_int <= 1'b1;
				 bgack_i_int <= 1'b1;
				 bgack_mb_int <= 1'b0;

					if( AS && !BG_I ) begin
						state <= 'd6;
						bgack_mb_int <= 1'b1;
						bgack_i_int <= 1'b0;
					end
			  end		
			  
			  4'd6: begin // RELINQUISH, AWAIT BG_MB
				 halt_mb_int <= 1'b0;
				 br_i_int <= 1'b0;
				 br_mb_int <= 1'b1;
				 bgack_i_int <= 1'b0;
				 bgack_mb_int <= 1'b1;

				 if( !BG_MB || ( BR_MB && BG_MB && BGACK_MB ) ) begin
					state <= 4'd0; // Back to initial state
				 end
			  end
			  
			endcase
		end
	end

	assign CLK8_O = CLK8;

	assign HALT_I = RESET_MB ? 1'bz : HALT_MB;
	assign HALT_MB = ( RESET_MB ? ( ( halt_mb_int === 1'bz ) ? 1'bz : halt_mb_int ) : 1'bz );
	//  assign BR_I = ( br_i_int === 1'bz ) ? 1'bz : br_i_int;
	assign BR_I = (state == 'd4) ? BR_MB : 1'b1;
	assign BR_MB = br_mb_int ? 1'bz : 1'b0;
	assign BGACK_I = ( bgack_i_int === 1'bz ) ? 1'bz : bgack_i_int;
	assign BGACK_MB = bgack_mb_int ? 1'bz : 1'b0;

/*
	assign HALT_I = 1'bz;
	assign HALT_MB = 1'bz;
	assign BR_I = 1'bz;
	assign BR_MB = 1'bz;
	assign BGACK_I = 1'bz;
	assign BGACK_MB = 1'bz;
*/

endmodule
