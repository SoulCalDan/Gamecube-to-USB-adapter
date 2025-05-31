
//--------------------------------------------------------------------------------------------------------
// Module  : usb_keyboard_top
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: A USB Full Speed (12Mbps) device, act as a USB HID keyboard
//--------------------------------------------------------------------------------------------------------

module usb_keyboard_top #(
    parameter          DEBUG = "FALSE"  // whether to output USB debug info, "TRUE" or "FALSE"
) (
    input  wire        rstn,          // active-low reset, reset when rstn=0 (USB will unplug when reset), normally set to 1
    input  wire        clk,           // 60MHz is required
    // USB signals
    output wire        usb_dp_pull,   // connect to USB D+ by an 1.5k resistor
    inout              usb_dp,        // USB D+
    inout              usb_dn,        // USB D-
    // USB reset output
    output wire        usb_rstn,      // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
    // HID keyboard press signal
    input  wire [159:0] key_value,     // Indicates which key to press, NOT ASCII code! see https://www.usb.org/sites/default/files/hut1_21_0.pdf section 10.
    input  wire        key_request,   // when key_request=1 pulses, a key is pressed.
    // debug output info, only for USB developers, can be ignored for normally use. Please set DEBUG="TRUE" to enable these signals
    output wire        debug_en,      // when debug_en=1 pulses, a byte of debug info appears on debug_data
    output wire [ 7:0] debug_data,    // 
    output wire        debug_uart_tx,  // debug_uart_tx is the signal after converting {debug_en,debug_data} to UART (format: 115200,8,n,1). If you want to transmit debug info via UART, you can use this signal. If you want to transmit debug info via other custom protocols, please ignore this signal and use {debug_en,debug_data}.
    output wire in_ready
);



//-------------------------------------------------------------------------------------------------------------------------------------
// HID keyboard IN data packet process
//-------------------------------------------------------------------------------------------------------------------------------------
reg  [167:0] in_data = 168'h0;//[23:0] in_data = 24'h0;
reg         in_valid = 1'b0;
reg  [ 7:0] in_cnt = 8'h00;

always @ (posedge clk or negedge usb_rstn)
    if (~usb_rstn) begin
        in_data <= 24'h0;
        in_valid <= 1'b0;
        in_cnt <= 8'h00;
    end else begin
        if (in_cnt == 8'd00) begin
            //in_data <= {key_value[7:0], 8'h0, key_value[15:8]};
            in_data <= { key_value[159:152], key_value[151:0] , 8'h0};
            if (key_request) begin
                in_valid <= 1'b1;
                in_cnt <= 8'd1;
            end
        end else if (in_cnt < 8'd21) begin //5'd17) begin    This counter is how many bytes to send plus one??? Not very flexible code.
            if (in_ready) begin
                //in_data <= {8'h0, in_data[23:8]}; //they're just doing this to bitshift????
                //in_data <= { in_data[151:0] ,8'h00 , in_data[159:152] }; 
                in_data <= in_data << 8;
                in_cnt <= in_cnt + 8'd1;
            end
        end else begin
            in_valid <= 1'b0;
            in_cnt <= 8'd0;
        end
    end


//-------------------------------------------------------------------------------------------------------------------------------------
// endpoint 00 (control endpoint) command response : HID descriptor
//-------------------------------------------------------------------------------------------------------------------------------------
wire [63:0] ep00_setup_cmd;
wire [ 8:0] ep00_resp_idx;
reg  [ 7:0] ep00_resp;

localparam [63*8-1:0] DESCRIPTOR_HID = 504'h05_01_09_06_a1_01_05_07_19_e0_29_e7_15_00_25_01_75_01_95_08_81_02_95_01_75_08_81_03_95_05_75_01_05_08_19_01_29_05_91_02_95_01_75_03_91_03_95_06_75_08_15_00_25_ff_05_07_19_00_29_65_81_00_c0;

always @ (posedge clk)
    if (ep00_setup_cmd[15:0] == 16'h0681)
        ep00_resp <= DESCRIPTOR_HID[ (63 - 1 - ep00_resp_idx) * 8 +: 8 ];
    else
        ep00_resp <= 8'h0;




//-------------------------------------------------------------------------------------------------------------------------------------
// USB full-speed core
//-------------------------------------------------------------------------------------------------------------------------------------
usbfs_core_top #(
    .DESCRIPTOR_DEVICE  ( {  //  18 bytes available
         144'h12_01_10_01_FF_FF_FF_40_5E_04_8E_02_14_01_01_02_03_01  
	   //144'h12_01_10_01_00_00_00_20_9A_FB_9A_FB_00_01_01_02_00_01// DEFAULT KEYBOARD
    } ),
    .DESCRIPTOR_STR1    ( {  //  64 bytes available
        //352'h2C_03_67_00_69_00_74_00_68_00_75_00_62_00_2e_00_63_00_6f_00_6d_00_2f_00_57_00_61_00_6e_00_67_00_58_00_75_00_61_00_6e_00_39_00_35_00,  // "github.com/WangXuan95"
        //160'h0
        256'h1E_03_47_00_4F_00_57_00_49_00_4E_00_46_00_50_00_47_00_41_00_44_00_45_00_56_00_49_00_43_00_45_00,     //GOWINFPGADEVICE
        256'h0
    } ),
    .DESCRIPTOR_STR2    ( {  //  64 bytes available
        //288'h24_03_46_00_50_00_47_00_41_00_2d_00_55_00_53_00_42_00_2d_00_4b_00_65_00_79_00_62_00_6f_00_61_00_72_00_64_00,                          // "FPGA-USB-Keyboard"
        //224'h0
        336'h2A_03_46_00_50_00_47_00_41_00_20_00_58_00_42_00_4F_00_58_00_20_00_43_00_4F_00_4E_00_54_00_52_00_4F_00_4C_00_4C_00_45_00_52_00, //FPGA XBOX CONTROLLER
        176'h0
    } ),
    .DESCRIPTOR_CONFIG  ( {  // 512 bytes available
//        72'h09_02_22_00_01_01_00_80_64,        // configuration descriptor 
//        72'h09_04_00_00_01_03_01_01_00,        // interface descriptor
//        72'h09_21_11_01_00_01_22_3f_00,        // HID descriptor
//        56'h07_05_81_03_08_00_64,              // endpoint descriptor (IN)
//        3824'h0
//        72'h09_02_22_00_01_01_00_80_64,        // configuration descriptor    
//        72'h09_04_00_00_01_03_01_01_00,        // interface descriptor
//        72'h09_21_11_01_00_01_22_3f_00,        // HID descriptor
//        56'h07_05_81_03_08_00_01,              // endpoint descriptor (IN)
//        3824'h0
          72'h09_02_31_00_01_01_00_80_FA,   
          72'h09_04_00_00_02_FF_5D_01_00,
         136'h11_21_10_01_01_25_81_14_03_03_03_04_13_01_08_03_03,
          56'h07_05_81_03_20_00_01,
          56'h07_05_01_03_20_00_01, 
        3704'h0 
    } ),
    .EP81_MAXPKTSIZE    ( 10'h14           ), //( 10'h08           ), //USB packet length? Will need to change this to match the XBOX360 controller data
    .DEBUG              ( DEBUG            )
) u_usbfs_core (
    .rstn               ( rstn             ),
    .clk                ( clk              ),
    .usb_dp_pull        ( usb_dp_pull      ),
    .usb_dp             ( usb_dp           ),
    .usb_dn             ( usb_dn           ),
    .usb_rstn           ( usb_rstn         ),
    .sot                (                  ),
    .sof                (                  ),
    .ep00_setup_cmd     ( ep00_setup_cmd   ),
    .ep00_resp_idx      ( ep00_resp_idx    ),
    .ep00_resp          ( ep00_resp        ),
    .ep81_data          ( in_data[167:160]     ), //( in_data[7:0]     ),
    .ep81_valid         ( in_valid         ),
    .ep81_ready         ( in_ready         ),
    .ep82_data          ( 8'h0             ),
    .ep82_valid         ( 1'b0             ),
    .ep82_ready         (                  ),
    .ep83_data          ( 8'h0             ),
    .ep83_valid         ( 1'b0             ),
    .ep83_ready         (                  ),
    .ep84_data          ( 8'h0             ),
    .ep84_valid         ( 1'b0             ),
    .ep84_ready         (                  ),
    .ep01_data          (                  ),
    .ep01_valid         (                  ),
    .ep02_data          (                  ),
    .ep02_valid         (                  ),
    .ep03_data          (                  ),
    .ep03_valid         (                  ),
    .ep04_data          (                  ),
    .ep04_valid         (                  ),
    .debug_en           ( debug_en         ),
    .debug_data         ( debug_data       ),
    .debug_uart_tx      ( debug_uart_tx    )
);


endmodule
