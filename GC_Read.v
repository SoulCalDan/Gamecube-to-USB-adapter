module GC_Read ( input clk , input POLL , input GC_enable ,
    output reg [80:0] GCdata = 0  , output reg testtoggle = 0
);                                                                                      
reg prev_POLL = 1; reg [7:0] count = 0; reg [6:0] bit_count = 0;  
always @ ( posedge clk ) begin
    prev_POLL <= POLL;
    //if ( count == 50 ) begin
    //    testtoggle <= ~testtoggle;        
    //end
    if ( GC_enable == 1 ) begin //GCdata[79:0] <= {8'h13,8'h40,48'h000000000000,16'h0000}; Testing if these bits propagate to USB protocol
        if ( prev_POLL && ~POLL ) begin // falling edge detected
            count <= 0;
            bit_count <= bit_count - 1;
            testtoggle <= ~testtoggle; 
        end

        if ( ~prev_POLL && ~POLL ) begin // controller line low
            count <= count + 1;
        end

        if ( ~prev_POLL && POLL ) begin // rising edge detected
            testtoggle <= ~testtoggle; 
            if ( count > 50 ) begin     
                count <= 0;
                GCdata[bit_count] <= 0; //bit_count <= bit_count - 1;
            end
            else begin
                count <= 0;
                GCdata[bit_count] <= 1; //bit_count <= bit_count - 1;
            end
        end

        if ( prev_POLL && POLL ) begin// controller line high
            if ( count > 100 ) begin //F*** the Phob controller. The bit delay to respond to the GC polling is so long it resets my counter.
                count <= 250;
                bit_count <= 80;    
            end
            else begin
                count <= count + 1;
            end
        end

    end
    else begin
        bit_count <= 80;
        count <= 0;
        prev_POLL <= 0;
    end
end

endmodule






