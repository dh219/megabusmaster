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
  output reg HALT_I,
  output reg BR_I,
  output reg BGACK_I
);

  reg [3:0] state = 4'd0;
  reg iBGACK_MB = 1'bz;
  reg iBR_MB = 1'bz;
  reg iHALT_MB = 1'bz;

  // Internal logic for state machine or control generation
  always @(posedge CLK8 or negedge RESET_MB) begin  
    if( !RESET_MB ) begin
      HALT_I <= 1'b0;
      iHALT_MB <= 1'b0;
      BR_I <= 1'b0;
      iBR_MB <= 1'bz;
      BGACK_I <= 1'b0;
      iBGACK_MB <= 1'bz;

      state <= 'd0; // Reset state
    end
    else begin
      case(state)
        4'd0: begin // BUS NOT OURS
          HALT_I <= 1'b1;
          iHALT_MB <= 1'b0;
          BR_I <= 1'b0;
          iBR_MB <= 1'bz;
          BGACK_I <= 1'b0;
          iBGACK_MB <= 1'bz;

          if( BR_MB && BGACK_MB && BG_MB ) begin
            state <= 4'd1; // If no bus arb in play, move to request state
          end
        end
      
        4'd1: begin // START REQUEST, WAIT BG
          HALT_I <= 1'b1;
          iHALT_MB <= 1'b0;
          BR_I <= 1'b0;
          iBR_MB <= 1'b0;
          BGACK_I <= 1'b0;
          iBGACK_MB <= 1'bz;

          if( !BG_MB && BGACK_MB ) begin
            state <= 4'd2; // If bus grant, move to accept state
          end
        end
        4'd2: begin // BUS IS MINE, AWAIT BR
          HALT_I <= 1'b1;
          iHALT_MB <= 1'b0;
          BR_I <= 1'b1;
          iBR_MB <= 1'bz;
          BGACK_I <= 1'b1;
          iBGACK_MB <= 1'b0;

          if( !BR_MB ) begin
            state <= 4'd3; // If bus request received, move to relinquish state
          end
        end
        4'd3: begin // BR RECEIVED, PASS THROUGH AND AWAIT BGI, WHILST STILL HOLDING BUS
          HALT_I <= 1'b1;
          iHALT_MB <= 1'b0;
          BR_I <= 1'b0;
          iBR_MB <= 1'bz;
          BGACK_I <= 1'b1;
          iBGACK_MB <= 1'b0;

          if( !BG_I ) begin
            state <= 4'd4; // If another request comes in move to relinquish
          end
        end
        4'd4: begin // RELINQUISH, AWAIT BG_MB
          HALT_I <= 1'b1;
          iHALT_MB <= 1'b0;
          BR_I <= 1'b0;
          iBR_MB <= 1'bz;
          BGACK_I <= 1'b0;
          iBGACK_MB <= 1'bz;

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

  always @(posedge CLK8 or negedge RESET_MB) begin  
    if( !RESET_MB ) begin
    end
    else begin
      case(state)
        4'd1: begin // START REQUEST, WAIT BG
        end

        4'd2: begin // CLAIM BUS
        end
        4'd2: begin // BR RECEIVED
        end
        4'd3: begin // BGI ISSUED, RELINQUISH
        end
/*        4'd4: begin // BGK RELEASED, PREPARE TO REQUEST AGAIN
          HALT_I <= 1'b1;
          iHALT_MB <= 1'b0;
          BR_I <= 1'b0;
          iBR_MB <= 1'bz;
          BGACK_I <= 1'b0;
          iBGACK_MB <= 1'bz;
        end
*/
      endcase
    end

  end

  assign CLK8_O = CLK8;
  assign BR_MB = ( iBR_MB == 1'bz ) ? 1'bz : iBR_MB;
  assign BGACK_MB = ( iBGACK_MB == 1'bz ) ? 1'bz : iBGACK_MB;
  assign HALT_MB = ( iHALT_MB == 1'bz ) ? 1'bz : iHALT_MB;
endmodule
