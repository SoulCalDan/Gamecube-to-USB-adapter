module GC_PollGen ( input clk , input ready ,//output reg GC_enable , 
    output reg GC_poll , output reg GC_enable //, input Rumble , input reset_polling
);
    //reg [35:0] Connect =    36'b0001_0001_0001_0001_0001_0001_0001_0001_0111;
    //reg [35:0] Sync =       36'b0001_0111_0001_0001_0001_0001_0001_0111_0111;
	reg [99:0] Controller; //reg [35:0] Origin;

	initial begin
	Controller = 100'b0001_0111_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0111_0111_0001_0001_0001_0001_0001_0001_0001_0001_0111;
	//Origin 	   = 36'b0001_0111_0001_0001_0001_0001_0001_0111_0111;
    end
	parameter bits = 7; //11; 
	reg [bits:0] bit_counter = 99;//bits_reset; 
	reg [5:0] clk_counter = 0; reg [6:0] readycnt;


always @ ( posedge clk ) begin //divide the 60MHz clk to 1MHz
    
    if ( ready ) begin      //This if/else controls when the polling of the GC controller begins, and sends the request to the controller
        readycnt <= 0;
        clk_counter <= 0;
        bit_counter <= 110;
    end
    else begin
        readycnt <= readycnt + 1;
        if ( readycnt > 50 ) begin 
            readycnt <= 121;
            clk_counter <= clk_counter + 1;
            if ( clk_counter == 57 ) begin 
                clk_counter <= 0;
                if ( bit_counter == 0 ) begin
                    GC_enable <= 1;
                    bit_counter <= 0;
                end
                else if ( bit_counter < 101 && bit_counter > 0 ) begin
                    GC_enable <= 0;
                    GC_poll <= Controller[bit_counter];
                    bit_counter <= bit_counter - 1;
                end
                else begin
                    GC_enable <= 1;
                    bit_counter <= bit_counter - 1;
                end
            end
        end
    end

end

endmodule