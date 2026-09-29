`timescale 1ns / 1ps

// main_top.v - Main module for the system

module main_top (
  input CLK8,
 
  input BG_I,
  input BG_MB,
 
  input RESET_I,
  input RESET_MB,

  inout BR_MB,
  inout BGACK_MB,
  inout HALT_MB,

  output CLK8_O,
  output HALT_I,
  output BR_I,
  output BGACK_I
);

  reg [3:0] state = 4'd0;

  reg halt_i_int = 1'bz;
  reg halt_mb_int = 1'bz;
  reg br_i_int = 1'bz;
  reg br_mb_int = 1'bz;
  reg bgack_i_int = 1'bz;
  reg bgack_mb_int = 1'bz;


  // Internal logic for state machine or control generation
  always @(posedge CLK8 or negedge RESET_MB) begin  
    if( !RESET_MB ) begin
      halt_i_int <= HALT_MB;
      halt_mb_int <= 1'bz;
      br_i_int <= 1'b0;
      br_mb_int <= 1'bz;
      bgack_i_int <= 1'b0;
      bgack_mb_int <= 1'bz;

      state <= 'd0; // Reset state
    end
    else begin
      case(state)
        4'd0: begin // BUS NOT OURS
          halt_i_int <= 1'bz;
          halt_mb_int <= 1'b0;
          br_i_int <= 1'b0;
          br_mb_int <= 1'bz;
          bgack_i_int <= 1'b0;
          bgack_mb_int <= 1'bz;

          if( BR_MB && BGACK_MB && BG_MB ) begin
            state <= 4'd1; // If no bus arb in play, move to request state
          end
        end
      
        4'd1: begin // START REQUEST, WAIT BG
          halt_i_int <= 1'bz;
          halt_mb_int <= 1'b0;
          br_i_int <= 1'b0;
          br_mb_int <= 1'b0;
          bgack_i_int <= 1'b0;
          bgack_mb_int <= 1'bz;

          if( !BG_MB && BGACK_MB ) begin
            state <= 4'd2; // If bus grant, move to accept state
          end
        end
        4'd2: begin // BUS IS MINE, AWAIT BR
          halt_i_int <= 1'bz;
          halt_mb_int <= 1'b0;
          br_i_int <= 1'b1;
          br_mb_int <= 1'bz;
          bgack_i_int <= 1'b1;
          bgack_mb_int <= 1'b0;

          if( !BR_MB ) begin
            state <= 4'd3; // If bus request received, move to relinquish state
          end
        end
        4'd3: begin // BR RECEIVED, PASS THROUGH AND AWAIT BGI, WHILST STILL HOLDING BUS
          halt_i_int <= 1'bz;
          halt_mb_int <= 1'b0;
          br_i_int <= 1'b0;
          br_mb_int <= 1'bz;
          bgack_i_int <= 1'b1;
          bgack_mb_int <= 1'b0;

          if( !BG_I ) begin
            state <= 4'd4; // If another request comes in move to relinquish
          end
        end
        4'd4: begin // RELINQUISH, AWAIT BG_MB
          halt_i_int <= 1'bz;
          halt_mb_int <= 1'b0;
          br_i_int <= 1'b0;
          br_mb_int <= 1'bz;
          bgack_i_int <= 1'b0;
          bgack_mb_int <= 1'bz;

          if( !BG_MB ) begin
            state <= 4'd0; // Back to initial state
          end
        end
        default: begin
          state <= 4'd0; // Default back to initial state
        end
      endcase
    end
//    state <= state + 'h1;
  end

  assign CLK8_O = CLK8;

  assign HALT_I = ( RESET_MB ? ( ( halt_i_int == 1'bz ) ? 1'bz : halt_i_int ) : HALT_MB );
  assign HALT_MB = ( RESET_MB ? ( ( halt_mb_int == 1'bz ) ? 1'bz : halt_mb_int ) : 1'bz );
  assign BR_I = ( br_i_int == 1'bz ) ? 1'bz : br_i_int;
  assign BR_MB = ( br_mb_int == 1'bz ) ? 1'bz : br_mb_int;
  assign BGACK_I = ( bgack_i_int == 1'bz ) ? 1'bz : bgack_i_int;
  assign BGACK_MB = ( bgack_mb_int == 1'bz ) ? 1'bz : bgack_mb_int;

endmodule

