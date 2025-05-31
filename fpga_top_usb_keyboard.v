
//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top_usb_keyboard
// Type    : synthesizable, fpga top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: example for usb_keyboard_top
//--------------------------------------------------------------------------------------------------------

module top (
    // clock
    input  wire        clk,     // connect to a 50MHz oscillator, 12MHz FOR UPDUINO
//	output wire 		the60clk ,
// reset button
    input  wire        button,       // connect to a reset button, 0=reset, 1=release. If you don't have a button, tie this signal to 1. 
    // LED
    output wire        led,          // 1: USB connected , 0: USB disconnected
	// USB signals
    output wire        usb_dp_pull,  // connect to USB D+ by an 1.5k resistor
    inout  wire            usb_dp,       // connect to USB D+ pin23
    inout  wire            usb_dn,       // connect to USB D- pin25
    inout  wire            lineGC1,
    // debug output info, only for USB developers, can be ignored for normally use
    output wire        uart_tx,       // If you want to see the debug info of USB device core, please connect this UART signal to host-PC (UART format: 115200,8,n,1), otherwise you can ignore this signal.
    output wire         testpin,
    wire in_ready,
    wire GC_poll , wire grnd

);

wire [79:0] GCdata1; 

//assign the60clk = clk60mhz;
assign testpin = testtoggle; 
assign grnd = 0;
assign lineGC1 = GC_poll ? 1'bZ : 1'b0;


//-------------------------------------------------------------------------------------------------------------------------------------
// The USB controller core needs a 60MHz clock, this PLL module is to convert clk50mhz to clk60mhz
// This PLL module is only available on Altera Cyclone IV E.
// If you use other FPGA families, please use their compatible primitives or IP-cores to generate clk60mhz
//-------------------------------------------------------------------------------------------------------------------------------------
//wire [3:0] subwire0;
wire       clk60mhz;
//wire       clk_locked;
//Gowin_PLLVR u_altpll (
//	.ref_clk_i(clk) ,//input clk  27MHz for GOWIN boards
//	.rst_n_i(1'b1),
 //   .outcore_o(clk60mhz) ,
  //  .outglobal_o());

//    Gowin_PLLVR u_altpll(
//        .clkout(clk60mhz), //output clkout
//        .clkin(clk) //input clkin
//    );

    Gowin_rPLL gowin_rpll(
        .clkout(clk60mhz), //output clkout
        .clkin(clk) //input clkin
    );

//-------------------------------------------------------------------------------------------------------------------------------------
// USB-HID keyboard device
//-------------------------------------------------------------------------------------------------------------------------------------

reg        key_request = 1'b1; //;key_request = 1'b0;
reg [159:0] key_value   = {16'h0014,48'h002000400060,48'h003005000080,48'habcdef561234}; // [15:0] key_value   = 16'h0004;

usb_keyboard_top #(
    .DEBUG           ( "FALSE"             )    // If you want to see the debug info of USB device core, set this parameter to "TRUE"
) usb_keyboard_i (
    .rstn            ( button ),
    .clk             ( clk60mhz            ),
    // USB signals
    .usb_dp_pull     ( usb_dp_pull         ),
    .usb_dp          ( usb_dp              ),
    .usb_dn          ( usb_dn              ),
    // USB reset output
    .usb_rstn        ( led                 ),   // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
    // HID keyboard press signal
    .key_value       ( key_value           ),   // key_value runs from 16'h0004 (a) to 16'h0027 (9). The keyboard will type a~z and 0~9 cyclically.
    .key_request     ( key_request         ),   // key_request=1 pulse every 2 seconds. The keyboard will press a key every 2 seconds.
    // debug output info, only for USB developers, can be ignored for normally use
    .debug_en        (                     ),
    .debug_data      (                     ),
    .debug_uart_tx   ( uart_tx             ),
    .in_ready        ( in_ready             )
);


//-------------------------------------------------------------------------------------------------------------------------------------
// Gamecube Controller Polling Data
//-------------------------------------------------------------------------------------------------------------------------------------

GC_PollGen  GC_PollGen1     ( .clk(clk60mhz) ,  .GC_poll(GC_poll) , .ready(in_ready) ,      .GC_enable(GC_enable) ); //,.GC_enable(GC_enable1),.Rumble(Rumble1),.reset_polling(reset_polling1));
bounce      bounce_GCC1     ( .clk(clk),        .line(lineGC1),    .enable(GC_enable),    .debounced(data_GCC) );
GC_Read     GC_Read1        ( .clk(clk) ,       .POLL(data_GCC) ,    .GC_enable(GC_enable) , .GCdata(GCdata1) , .testtoggle(testtoggle) ); //, .test(test1) ); 

//-------------------------------------------------------------------------------------------------------------------------------------
// XBOX Controller Data
//-------------------------------------------------------------------------------------------------------------------------------------

reg [18:0] count = 0;             // count is a clock counter that runs from 0 to 120000000, each period takes 2 seconds
reg Abutton = 0;
always @ ( * ) begin
        //key_request <= 1'b1;      // press a key per 2 seconds
        //GC DATA   0 0 0 St Y X B A 1 L R Z DU DD DR DL JX JY CX CY AL AR
        // XBOX DATA R3 L3 BACK St DR DL DD DU Y X B A 0 Home RB LB 8LT 8RT 16LS 16RS
        key_value = {16'h0014, //required start of USB packet
        1'b0,1'b0,1'b0,GCdata1[76],GCdata1[65],GCdata1[64],GCdata1[66],GCdata1[67], // 8 bits button data (click stick not applicable)
        GCdata1[75:72],1'b0,1'b0,GCdata1[68],1'b0, // 8 bits button data (BACK and XBOX button not compatible with GC) 
        GCdata1[31:24],GCdata1[23:16], //Analog Triggers
        8'h00 , { ~GCdata1[63] , GCdata1[62:56] } , 8'h00 , { ~GCdata1[55] , GCdata1[54:48] } , 8'h00 , { ~GCdata1[47] , GCdata1[46:40] } , 8'h00 , { ~GCdata1[39] , GCdata1[38:32] } , //64'h00000000, //All Analog Stick data here
        48'h0 }; //padding for the total 80bytes sent
    end

//reg [7:0] XBOX_LX=8'd127; reg[7:0] XBOX_LY=8'd127; reg [7:0] XBOX_RX=8'd127; reg[7:0] XBOX_RY=8'd127;
//always @ ( * ) begin    //convert GC 8 bit unsigned integer to XBOX 16bit signed integer (little indian)
//    XBOX_LX = { ~GCdata1[63] , GCdata1[62:56] };
//    XBOX_LY = { ~GCdata1[55] , GCdata1[54:48] };
//    XBOX_RX = { ~GCdata1[47] , GCdata1[46:40] };
//    XBOX_RY = { ~GCdata1[39] , GCdata1[38:32] };
//end

endmodule