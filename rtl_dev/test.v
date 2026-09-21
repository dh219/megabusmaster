module test;

	// regs
  reg CLK8;

  reg RESET_I;
  reg RESET_MB;
  
  reg BG_I;
  reg BG_MB;
 
	// Outputs
	wire CLK8_O;

  wire HALT_I;
  wire BR_I;
  wire BGACK_I;

// inout
  wire BR_MB;
  pullup( BR_MB );
  reg BR_MB_val;
  reg BR_MB_en;
  assign BR_MB = BR_MB_en ? BR_MB_val : 1'bz;
  assign BR_MB_read = BR_MB_en ? BR_MB_val : BR_MB;

  wire BGACK_MB;
  pullup( BGACK_MB );
  reg BGACK_MB_val;
  reg BGACK_MB_en;
  assign BGACK_MB = BGACK_MB_en ? BGACK_MB_val : 1'bz;

  wire HALT_MB;  
  pullup( HALT_MB );
  reg HALT_MB_val;
  reg HALT_MB_en;
  assign HALT_MB = HALT_MB_en ? HALT_MB_val : 1'bz;
  assign HALT_MB_read = HALT_MB_en ? HALT_MB_val : HALT_MB;


	// Instantiate the Unit Under Test (UUT)
	main_top uut (
    .CLK8(CLK8),
    .CLK8_O(CLK8_O),

    .RESET_I(RESET_I),
    .RESET_MB(RESET_MB),

    .HALT_I(HALT_I),
    .HALT_MB(HALT_MB),

    .BR_I(BR_I),
    .BR_MB(BR_MB),

    .BG_I(BG_I),
    .BG_MB(BG_MB),

    .BGACK_I(BGACK_I),
    .BGACK_MB(BGACK_MB)
	);

	initial begin
		$dumpfile("wave.vcd");
		$dumpvars(0, uut);
	 
		// Initialize Inputs
		CLK8 = 0;
    RESET_I = 0;
		RESET_MB = 0;

    BR_MB_val = 1'bz;
    BR_MB_en = 1'b0;

    BGACK_MB_val = 1'b0;
    BGACK_MB_en = 1'b0;

    HALT_MB_val = 1'b0;
    HALT_MB_en = 1'b0;
  
    BG_I = 1;
    BG_MB = 1;
  //    BGACK_I = 0;
  //    BGACK_MB = 0;

		// Wait 100 ns for global reset to finish
		#100;
		// Add stimulus here
    RESET_MB = 1;
    RESET_I = 1;

    #400;
    BG_MB = 0;

    #400;
    BG_MB = 1;

    #900;
    BR_MB_val = 1'b0;
    BR_MB_en = 1'b1;

    #400;
    BG_I = 0;
    #350;
    BG_MB = 0;

    #100;
    BGACK_MB_en = 1'b1;
    BR_MB_en = 1'b0;

    #125;
    BG_MB = 1;

    #1250;
    BGACK_MB_en  = 1'b0;

	end

//	initial #447 SWITCH=0;
	
	initial #5000 $finish;


	always #62 CLK8 = ~CLK8;

      
endmodule

