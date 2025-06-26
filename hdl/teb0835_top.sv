`timescale 1ns / 1ps
`include "interfaces.vh"
module teb0835_top(
        input VP,   // no pin loc
        input VN,   // no pin loc
        input ADC0_CLK_P,   // AD5
        input ADC0_CLK_N,   // AD4
        input ADC0_VIN_P,   // AK2
        input ADC0_VIN_N,   // AK1
        input ADC1_VIN_P,   // AH2
        input ADC1_VIN_N,   // AH1
        input ADC2_CLK_P,   // AB5
        input ADC2_CLK_N,   // AB4
        input ADC2_VIN_P,   // AF2
        input ADC2_VIN_N,   // AF1
        input ADC3_VIN_P,   // AD2
        input ADC3_VIN_N,   // AD1
        input ADC4_CLK_P,   // Y5
        input ADC4_CLK_N,   // Y4
        input ADC4_VIN_P,   // AB2
        input ADC4_VIN_N,   // AB1
        input ADC5_VIN_P,   // Y2
        input ADC5_VIN_N,   // Y1
        input ADC6_CLK_P,   // V5
        input ADC6_CLK_N,   // V4
        input ADC6_VIN_P,   // V2
        input ADC6_VIN_N,   // V1
        input ADC7_VIN_P,   // T2
        input ADC7_VIN_N,   // T1
        
        input SYSREF_P, // N5 - this is CLKOUT7 from si5395 on carrier
        input SYSREF_N, // N4
        
        // The TEB0835 sucks because they forgot to hook the two Si5395s
        // together and none of the outputs of the board's Si5395 can go
        // to the FPGA. So we jumpered over one of the outputs
        // to CLKIN2 to connect them.
        
        // The SI5395 on carrier generates
        // CLKOUT0A = B128_CLK1_P/N (MGT REFCLK)
        // CLKOUT0 = B129_CLK1_P/N (MGT REFCLK)
        // PLLCLK1 = ADC_CLK_224
        // PLLCLK2 = ADC_CLK_225
        // PLLCLK3 = ADC_CLK_226
        // PLLCLK4 = ADC_CLK_227
        // PLLCLK5 = DAC_CLK_228
        // PLLCLK6 = DAC_CLK_229
        // 
        // On the MODULE, the Si5395 generates
        // CLKOUT0 = CLKC_P/N (unused)
        // CLKOUT1 = CLKB_P/N (unused)
        // CLKOUT2 = CLKA_P/N (unused)
        // CLKOUT3 = CLKD_P/N (test points TP20/21)
        // CLKOUT4 = CLKE_P/N (test points TP16/17)
        // CLKOUT5 = CLKF_P/N (test points TP18/19)
        //
        // So in the end we have a REFCLK_P/N which is 375 MHz, coming from
        // the module Si5395. 
        //input REFCLK_P, // AG17
        //input REFCLK_N, // AH17
        // That then is fed into an MMCM and divided *down* to capture the
        // REFCLK. The capture obviously sucks 
        // sigh, let's see what happens if we use an MGT refclk
        input MGT_REFCLK_P, // K28
        input MGT_REFCLK_N // K29
        // no local SYSREF, we just effing make it up        
    );

    parameter THIS_DESIGN = "FILTER_CHAIN_LOWPASS_ONLY";
        
        (* KEEP = "TRUE" *)
        wire ps_clk;
        wire ps_reset;
        
        // adc axi4-stream clock
        wire aclk_in;
        wire aclk;
        wire aclk_div2;
        wire aclk_locked;
        IBUFDS_GTE4 #(.REFCLK_EN_TX_PATH(1'b0),
                    .REFCLK_HROW_CK_SEL(2'b00),
                    .REFCLK_ICNTL_RX(2'b00)) 
                    u_ibuf(.I(MGT_REFCLK_P),.IB(MGT_REFCLK_N),.CEB(1'b0),
                        .ODIV2(aclk_in));
        BUFG_GT u_bufg(.I(aclk_in),
                    .O(aclk),
                    .CE(1'b1),
                    .CEMASK(1'b0),
                    .CLR(1'b0),
                    .CLRMASK(1'b0),
                    .DIV(3'b000));
        refclk_wiz u_wiz(.reset(1'b0),.clk_in1(aclk),
                        .clk_out1(aclk_div2),
                        .locked(aclk_locked));
        `DEFINE_AXI4S_MIN_IF( adc0_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc1_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc2_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc3_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc4_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc5_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc6_ , 128);
        `DEFINE_AXI4S_MIN_IF( adc7_ , 128);
        // buffer inputs
        `DEFINE_AXI4S_MIN_IF( buf0_ , 128);
        `DEFINE_AXI4S_MIN_IF( buf1_ , 128);
        `DEFINE_AXI4S_MIN_IF( buf2_ , 128);
        `DEFINE_AXI4S_MIN_IF( buf3_ , 128);
            
        // DAC output. Note that the DAC works
        // at aclk rate, not aclk_div2 rate like some other
        // designs.
        `DEFINE_AXI4S_MIN_IF( dac0_ , 128 );  
        
        // PS UART
        wire uart_to_ps;
        wire uart_from_ps;
        // PS capture
        wire capture;
        
        
        // sysref externally is 375/48 so we ultrafake here
        // this is a 1/24th divide
        wire toggle_sysref;
        clk_div_ce #(.CLK_DIVIDE(23),.EXTRA_DIV2("FALSE"))
            u_sysref_toggle_ce(.clk(aclk),.ce(toggle_sysref));
        reg my_sysref = 0;
        always @(posedge aclk) if (toggle_sysref) my_sysref <= ~my_sysref;    
        
        wire adc_clk;
        
        reg [31:0] pps_counter = {32{1'b0}};
        reg pps_flag = 0;
        wire pps_flag_aclk;
        wire aclk_freq_done;
        wire pps_flag_aclkdiv2;
        wire aclkdiv2_freq_done;
        
        reg [31:0] aclk_counter = {32{1'b0}};
        (* CUSTOM_CC_SRC = "ACLK" *)
        reg [31:0] aclk_freq = {32{1'b0}};
        (* CUSTOM_CC_DST = "PSCLK" *)
        reg [31:0] aclk_freq_ps = {32{1'b0}};
        
        // dafuq
        reg [31:0] aclk_div2_counter = {32{1'b0}};
        (* CUSTOM_CC_SRC = "ACLKDIV2" *)
        reg [31:0] aclk_div2_freq = {32{1'b0}};
        (* CUSTOM_CC_DST = "PSCLK" *)
        reg [31:0] aclk_div2_freq_ps = {32{1'b0}};
        
        (* ASYNC_REG = "TRUE" *)
        reg [1:0] aclk_locked_ps = {2{1'b0}};
        
        always @(posedge aclk) begin
            if (pps_flag_aclk) aclk_counter <= {32{1'b0}};
            else aclk_counter <= aclk_counter + 1;
            
            if (pps_flag_aclk) aclk_freq <= aclk_counter;
        end
        always @(posedge aclk_div2) begin
            if (pps_flag_aclkdiv2) aclk_div2_counter <= {32{1'b0}};
            else aclk_div2_counter <= aclk_div2_counter + 1;
            
            if (pps_flag_aclkdiv2) aclk_div2_freq <= aclk_div2_counter;        
        end        
        always @(posedge ps_clk) begin
            if (pps_counter == 100000000 - 1) pps_counter <= {32{1'b0}};
            else pps_counter <= pps_counter + 1;
            
            pps_flag <= (pps_counter == {32{1'b0}});
            if (aclk_freq_done) aclk_freq_ps <= aclk_freq;
            
            if (aclkdiv2_freq_done) aclk_div2_freq_ps <= aclk_div2_freq;
            
            aclk_locked_ps <= { aclk_locked_ps[0], aclk_locked };
        end
        flag_sync u_pps_flag_sync(.in_clkA(pps_flag),.out_clkB(pps_flag_aclk),.clkA(ps_clk),.clkB(aclk));
        flag_sync u_aclk_freq_done_sync(.in_clkA(pps_flag_aclk),.out_clkB(aclk_freq_done),.clkA(aclk),.clkB(ps_clk));

        flag_sync u_pps_flag_sync_div2(.in_clkA(pps_flag),.out_clkB(pps_flag_aclkdiv2),.clkA(ps_clk),.clkB(aclk_div2));
        flag_sync u_aclkdiv2_done_sync(.in_clkA(pps_flag_aclkdiv2),.out_clkB(aclkdiv2_freq_done),.clkA(aclk_div2),.clkB(ps_clk));
        
        clk_count_vio u_vio(.clk(ps_clk),
                            .probe_in0(aclk_freq_ps),
                            .probe_in1(aclk_div2_freq_ps),
                            .probe_in2(aclk_locked_ps[1]));         

        `DEFINE_WB_IF( bm_ , 22, 32 );
        boardman_wrapper #(.CLOCK_RATE(100000000),
                        .BAUD_RATE(1000000),
                        .USE_ADDRESS("FALSE"))
                        u_bm(.wb_clk_i(ps_clk),
                                .wb_rst_i(1'b0),
                                `CONNECT_WBM_IFM( wb_ , bm_ ),
                                .burst_size_i(2'b00),
                                .address_i(8'h00),
                                .RX(uart_from_ps),
                                .TX(uart_to_ps));

        zynqmp_wrapper u_ps(.Vp_Vn_0_v_p( VP ),
                            .Vp_Vn_0_v_n( VN ),
                            .sysref_in_0_diff_p( SYSREF_P ),
                            .sysref_in_0_diff_n( SYSREF_N ),
                            .adc0_clk_0_clk_p( ADC0_CLK_P ),
                            .adc0_clk_0_clk_n( ADC0_CLK_N ),
                            .adc1_clk_0_clk_p( ADC2_CLK_P ),
                            .adc1_clk_0_clk_n( ADC2_CLK_N ),
                            .adc2_clk_0_clk_p( ADC4_CLK_P ),
                            .adc2_clk_0_clk_n( ADC4_CLK_N ),
                            .adc3_clk_0_clk_p( ADC6_CLK_P ),
                            .adc3_clk_0_clk_n( ADC6_CLK_N ),
                            .vin0_01_0_v_p( ADC0_VIN_P ),
                            .vin0_01_0_v_n( ADC0_VIN_N ),
                            .vin0_23_0_v_p( ADC1_VIN_P ),
                            .vin0_23_0_v_n( ADC1_VIN_N ),
                            .vin1_01_0_v_p( ADC2_VIN_P ),
                            .vin1_01_0_v_n( ADC2_VIN_N ),
                            .vin1_23_0_v_p( ADC3_VIN_P ),
                            .vin1_23_0_v_n( ADC3_VIN_N ),
                            .vin2_01_0_v_p( ADC4_VIN_P ),
                            .vin2_01_0_v_n( ADC4_VIN_N ),
                            .vin2_23_0_v_p( ADC5_VIN_P ),
                            .vin2_23_0_v_n( ADC5_VIN_N ),
                            .vin3_01_0_v_p( ADC6_VIN_P ),
                            .vin3_01_0_v_n( ADC6_VIN_N ),
                            .vin3_23_0_v_p( ADC7_VIN_P ),
                            .vin3_23_0_v_n( ADC7_VIN_N ),
                            
                            .vout00_0_v_n( DAC0_VOUT_P ),
                            .vout00_0_v_p( DAC0_VOUT_N ),
                            
                            `CONNECT_AXI4S_MIN_IF( m00_axis_0_ , adc0_ ),
                            `CONNECT_AXI4S_MIN_IF( m02_axis_0_ , adc1_ ),
                            `CONNECT_AXI4S_MIN_IF( m10_axis_0_ , adc2_ ),
                            `CONNECT_AXI4S_MIN_IF( m12_axis_0_ , adc3_ ),
                            `CONNECT_AXI4S_MIN_IF( m20_axis_0_ , adc4_ ),
                            `CONNECT_AXI4S_MIN_IF( m22_axis_0_ , adc5_ ),
                            `CONNECT_AXI4S_MIN_IF( m30_axis_0_ , adc6_ ),
                            `CONNECT_AXI4S_MIN_IF( m32_axis_0_ , adc7_ ),
                            
                            `CONNECT_AXI4S_MIN_IF( s00_axis_0_ , dac0_ ),
                            
                            .s_axi_aclk_0( aclk_div2 ),
                            .s_axi_aresetn_0( 1'b1 ),
                            .s_axis_aclk_0( aclk ),
                            .s_axis_aresetn_0( 1'b1 ),
                            `CONNECT_AXI4S_MIN_IF( S_AXIS_0_ , buf0_ ),
                            `CONNECT_AXI4S_MIN_IF( S_AXIS_1_ , buf1_ ),
                            `CONNECT_AXI4S_MIN_IF( S_AXIS_2_ , buf2_ ),
                            `CONNECT_AXI4S_MIN_IF( S_AXIS_3_ , buf3_ ),
                            
                            .UART_txd(uart_from_ps),
                            .UART_rxd(uart_to_ps),
                            
                            .capture_o(capture),
                            
                            .pl_clk0( ps_clk ),
                            .pl_resetn0( ps_reset ),
                            .clk_adc0_0(adc_clk),
                            .user_sysref_adc_0( my_sysref ));    

        generate
            if (THIS_DESIGN == "BASIC") begin : BSC
                // basic design doesn't bother with the DAC,
                // whatever.
                basic_design u_design( .wb_clk_i(ps_clk),
                                    .wb_rst_i(1'b0),
                                        `CONNECT_WBS_IFS( wb_ , bm_ ),
                                        .aclk(aclk),
                                        .aresetn(1'b1),
                                        `CONNECT_AXI4S_MIN_IF( adc0_ , adc0_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc1_ , adc1_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc2_ , adc2_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc3_ , adc3_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc4_ , adc4_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc5_ , adc5_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc6_ , adc6_ ),
                                        `CONNECT_AXI4S_MIN_IF( adc7_ , adc7_ ),
                                        // buffers
                                        `CONNECT_AXI4S_MIN_IF( buf0_ , buf0_ ),
                                        `CONNECT_AXI4S_MIN_IF( buf1_ , buf1_ ),
                                        `CONNECT_AXI4S_MIN_IF( buf2_ , buf2_ ),
                                        `CONNECT_AXI4S_MIN_IF( buf3_ , buf3_ ));            
            end else if (THIS_DESIGN == "AGC") begin : AGC
                // our DACs are at 375M so they don't need a dac transfer,
                // so we can just directly connect them
                agc_design u_design( .wb_clk_i(ps_clk),
                                    .wb_rst_i(1'b0),
                                    `CONNECT_WBS_IFM( wb_ , bm_ ),
                                    .aclk(aclk),
                                    .aresetn(1'b1),
                                    `CONNECT_AXI4S_MIN_IF( adc0_ , adc0_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc1_ , adc1_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc2_ , adc2_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc3_ , adc3_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc4_ , adc4_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc5_ , adc5_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc6_ , adc6_ ),
                                    `CONNECT_AXI4S_MIN_IF( adc7_ , adc7_ ),
                                    // buffers
                                    `CONNECT_AXI4S_MIN_IF( buf0_ , buf0_ ),
                                    `CONNECT_AXI4S_MIN_IF( buf1_ , buf1_ ),
                                    `CONNECT_AXI4S_MIN_IF( buf2_ , buf2_ ),
                                    `CONNECT_AXI4S_MIN_IF( buf3_ , buf3_ ),
                                    // DACs
                                    `CONNECT_AXI4S_MIN_IF( dac0_ , dac0_ )
                                    );            
                
            end else if (THIS_DESIGN == "FILTER_CHAIN") begin : FILTER_CHAIN
                `DEFINE_AXI4S_MIN_IF( design_dac0_ , 128 );
                
                filter_chain_design #(.NBEAMS(2))
                                u_design(     .wb_clk_i(ps_clk),
                                                .wb_rst_i(1'b0),
                                                `CONNECT_WBS_IFM( wb_ , bm_ ),    
                                                .aclk(aclk),
                                                .reset_i(1'b0),
                                                `CONNECT_AXI4S_MIN_IF( adc0_ , adc0_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc1_ , adc1_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc2_ , adc2_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc3_ , adc3_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc4_ , adc4_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc5_ , adc5_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc6_ , adc6_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc7_ , adc7_ ),
                                                // Buffers
                                                `CONNECT_AXI4S_MIN_IF( buf0_ , buf0_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf1_ , buf1_ ),
                                                // DACs
                                                `CONNECT_AXI4S_MIN_IF( dac0_ , dac0_ ));

            end else if (THIS_DESIGN == "FILTER_CHAIN_NO_BIQUAD") begin : NO_BIQUAD
                `DEFINE_AXI4S_MIN_IF( design_dac0_ , 128 );
                
                filter_chain_no_biquad_design #(.NBEAMS(2))
                                u_design(     .wb_clk_i(ps_clk),
                                                .wb_rst_i(1'b0),
                                                `CONNECT_WBS_IFM( wb_ , bm_ ),    
                                                .aclk(aclk),
                                                .reset_i(1'b0),
                                                `CONNECT_AXI4S_MIN_IF( adc0_ , adc0_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc1_ , adc1_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc2_ , adc2_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc3_ , adc3_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc4_ , adc4_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc5_ , adc5_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc6_ , adc6_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc7_ , adc7_ ),
                                                // Buffers
                                                `CONNECT_AXI4S_MIN_IF( buf0_ , buf0_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf1_ , buf1_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf2_ , buf2_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf3_ , buf3_ ),
                                                // DACs
                                                `CONNECT_AXI4S_MIN_IF( dac0_ , dac0_ ));
 
            end else if (THIS_DESIGN == "FILTER_CHAIN_LOWPASS_ONLY") begin : LOWPASS_ONLY
                `DEFINE_AXI4S_MIN_IF( design_dac0_ , 128 );
                
                lowpass_design  u_design(     .wb_clk_i(ps_clk),
                                                .wb_rst_i(1'b0),
                                                `CONNECT_WBS_IFM( wb_ , bm_ ),    
                                                .aclk(aclk),
                                                `CONNECT_AXI4S_MIN_IF( adc0_ , adc0_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc1_ , adc1_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc2_ , adc2_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc3_ , adc3_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc4_ , adc4_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc5_ , adc5_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc6_ , adc6_ ),
                                                `CONNECT_AXI4S_MIN_IF( adc7_ , adc7_ ),
                                                // Buffers
                                                `CONNECT_AXI4S_MIN_IF( buf0_ , buf0_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf1_ , buf1_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf2_ , buf2_ ),
                                                `CONNECT_AXI4S_MIN_IF( buf3_ , buf3_ ),
                                                // DACs
                                                `CONNECT_AXI4S_MIN_IF( dac0_ , dac0_ ));

            end
        endgenerate

endmodule
