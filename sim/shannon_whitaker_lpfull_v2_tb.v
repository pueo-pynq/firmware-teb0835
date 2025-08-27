//////////////////////////////////////////////////////////////////////////////////
// Michael Betts Mon Aug 12 12:03:00 EDT 2024
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

//////////////////////////////////////////////////////////////////////////////////
// Test cases
//////////////////////////////////////////////////////////////////////////////////
`define TEST_CASE_1 // analyzing default behavior
// `define TEST_CASE_2

module shannon_whitaker_lpfull_v2_tb;
   
   //////////////////////////////////////////////////////////////////////
   // I/O
   //////////////////////////////////////////////////////////////////////   
   parameter CLK_PERIOD = 10;
   reg clk=0;
   reg clk2=0;
   reg rst;

   // Connections
   wire [47:0] out_o;
   wire [19:0] out_o_small;
   reg [47:0] in_i;
   wire [95:0] out_o2;
   wire [39:0] out_o2_small;
   reg [95:0] in_i2;
   reg [95:0] in_i2_clk1;
   
   //////////////////////////////////////////////////////////////////////
   // Clock Driver
   //////////////////////////////////////////////////////////////////////
   always @(clk)
     #(CLK_PERIOD / 2.0) clk <= !clk;
   always @(posedge clk)
     clk2 <=!clk2;
   
				   
   //////////////////////////////////////////////////////////////////////
   // Simulated interfaces
   //////////////////////////////////////////////////////////////////////   
   
   //////////////////////////////////////////////////////////////////////
   // Functions
   //////////////////////////////////////////////////////////////////////   
   
   //////////////////////////////////////////////////////////////////////
   // UUT
   //////////////////////////////////////////////////////////////////////   
	reg [47:0] in_i_clked;
	reg [14:0] count0 = 5'd0;
	reg [14:0] count1 = 5'd1;
	reg [14:0] count2 = 5'd2;
	reg [14:0] count3 = 5'd3;
//   shannon_whitaker_lpfull_vlowampa #(.NBITS(12),.OUTQ_INT(12),.OUTQ_FRAC(0))
//      test_lowampa(.clk_i(clk),
//		.in_i(in_i_clked),
//		.out_o(out_o) );
//		shannon_whitaker_lpfull_v2 #(.NBITS(12),.OUTQ_INT(12),.OUTQ_FRAC(0))
//      test_lpfull(.clk_i(clk2),
//		.in_i(in_i2),
//		.out_o(out_o2) );

//    matched_filter
//      test_main(.aclk(clk2),
//		.data_i(in_i2),
//		.data_o(out_o2) );
//    matched_filter_lowampa
//      test_lowampa(.aclk(clk),
//		.data_i(in_i_clked),
//		.data_o(out_o) );

  
//      agc_wrapper
//        test_main(.aclk(clk2),
//        .wb_clk_i(0),
//        .wb_rst_i(0),  
//        .aresetn(1),
//		.dat_i(in_i2),
//		.dat_o(out_o2_small) );
//	  agc_wrapper_lowampa
//        test_lowampa(.aclk(clk),
//        .wb_clk_i(0),
//        .wb_rst_i(0),      
//        .aresetn(1),
//		.dat_i(in_i_clked),
//		.dat_o(out_o_small) );
//		assign out_o2 = {7'b0,out_o2_small[39:35],7'b0,out_o2_small[34:30],7'b0,out_o2_small[29:25],7'b0,out_o2_small[24:20],7'b0,out_o2_small[19:15],7'b0,out_o2_small[14:10],7'b0,out_o2_small[9:5],7'b0,out_o2_small[4:0]};
//		assign out_o = {7'b0,out_o_small[19:15],7'b0,out_o_small[14:10],7'b0,out_o_small[9:5],7'b0,out_o_small[4:0]};
		
		
		
		dual_pueo_lowampa_envelope_v2
		test_beam(
		.clk_i(clk),
        .squareA_i({count3,count2,count1,count0}),
        .squareB_i(0),
        .envelopeA_o(),
        .envelopeB_o());
		
		lowampa_matched_filter_v2
		test_matched(
		.clk_i(clk),
        //.in_i((count0==48'd1000)?48'h200040008001:48'b0),
        .in_i((count0==48'd1000)?48'h000000000001:48'b0),
        .out_o(out_o));
        
        lowampa_trigger_chain_x8_wrapper
        test(
        .wb_clk_i(clk),
        .wb_rst_i(1'b0),
        // Control to capture the output to the RAM buffer
        .reset_i(0), 
        .aclk(clk),
        .dat_i(0) 
         
        );
		

	always @(negedge clk)
	begin
	   in_i_clked <= in_i;
	   in_i2 <= {in_i,in_i2[95:48]};
	   count0 <= count0+4;
	   count1 <= count1+4;
	   count2 <= count2+4;
	   count3 <= count3+4;
	end

   //////////////////////////////////////////////////////////////////////
   // Testbench
   //////////////////////////////////////////////////////////////////////   
   initial
     begin
	// Initializations
	clk = 1'b0;
	rst = 1'b1;
	in_i = 96'b0; 
     end

   //////////////////////////////////////////////////////////////////////
   // Test case
   //////////////////////////////////////////////////////////////////////   
`ifdef TEST_CASE_1
   integer i; 
   initial
     begin
	i=0; 
	// Reset	
	#(10 * CLK_PERIOD);
	rst = 1'b0;
	#(20* CLK_PERIOD);
	
	// Logging
	$display("");
	$display("------------------------------------------------------");
	$display("Test Case: TEST_CASE_1");

	//Reset the PL
       	in_i = {12'h000,12'h000,12'h000,12'h000,12'h000,12'h000,12'h000,12'h000};
	#(CLK_PERIOD*5)
//       	in_i = {12'hfff,12'hfff,12'hfff,12'hfff,12'hfff,12'hfff,12'hfff,12'hfff};
//	#(CLK_PERIOD*100)
//       	in_i = {12'h500,12'h500,12'h500,12'h500,12'h500,12'h500,12'h500,12'h500};
//	#(CLK_PERIOD*100)
     begin
    for(i=0;i<1000;i=i+1)
begin
#(CLK_PERIOD)
//if(i==0)
//begin
//in_i= {48'h000000000001};
//end
//if(i==1)
//begin
//in_i= {48'h000000000002};
//end
//if(i==2)
//begin
//in_i= {48'h000000000003};
//end
//if(i==3)
//begin
//in_i= {48'h000000000004};
//end
//if(i==4)
//begin
//in_i= {48'h000000000005};
//end
//if(i==5)
//begin
//in_i= {48'h000000000006};
//end
//if(i==6)
//begin
//in_i= {48'h000000000007};
//end
//if(i==7)
//begin
//in_i= {48'h000000000008};
//end
//if(i==8)
//begin
//in_i= {48'h000000000009};
//end
//if(i==9)
//begin
//in_i= {48'h0000000000010};
//end
//if(i==10)
//begin
//in_i= {48'h09F17E1560BF};
//end
//if(i==11)
//begin
//in_i= {48'h0E009D178110};
//end
//if(i==12)
//begin
//in_i= {48'h1920C90BB17E};
//end
//if(i==13)
//begin
//in_i= {48'h1451B00CD0F4};
//end
//if(i==14)
//begin
//in_i= {48'h1221A71D70EC};
//end
//if(i==15)
//begin
//in_i= {48'h22E16B211202};
//end
//if(i==16)
//begin
//in_i= {48'h2D92561C027A};
//end
//if(i==17)
//begin
//in_i= {48'h26F325276219};
//end
//if(i==18)
//begin
//in_i= {48'h2942BA35928C};
//end
//if(i==19)
//begin
//in_i= {48'h36528E2F536F};
//end
//if(i==20)
//begin
//in_i= {48'h32433C27B319};
//end
//if(i==21)
//begin
//in_i= {48'h2313162F825B};
//end
//if(i==22)
//begin
//in_i= {48'h2362022F029E};
//end
//if(i==23)
//begin
//in_i= {48'h26C1C91D22B6};
//end
//if(i==24)
//begin
//in_i= {48'h18021A1601A5};
//end
//if(i==25)
//begin
//in_i= {48'h0BE1661C7104};
//end
//if(i==26)
//begin
//in_i= {48'h13909315A17A};
//end
//if(i==27)
//begin
//in_i= {48'h17010B08815D};
//end
//if(i==28)
//begin
//in_i= {48'h0D11910F309D};
//end
//if(i==29)
//begin
//in_i= {48'h10911E1BC0F2};
//end
//if(i==30)
//begin
//in_i= {48'h2251351801EF};
//end
//if(i==31)
//begin
//in_i= {48'h25B2581721ED};
//end
//if(i==32)
//begin
//in_i= {48'h2082C32841BB};
//end
//if(i==33)
//begin
//in_i= {48'h2B72543192A5};
//end
//if(i==34)
//begin
//in_i= {48'h3782B8297357};
//end
//if(i==35)
//begin
//in_i= {48'h2ED3792A92CB};
//end
//if(i==36)
//begin
//in_i= {48'h25C2FA359289};
//end
//if(i==37)
//begin
//in_i= {48'h2C42262F031B};
//end
//if(i==38)
//begin
//in_i= {48'h2A125D1EB2D2};
//end
//if(i==39)
//begin
//in_i= {48'h17C2631ED1B1};
//end
//if(i==40)
//begin
//in_i= {48'h11C15321E17F};
//end
//if(i==41)
//begin
//in_i= {48'h1940CC1381D7};
//end
//if(i==42)
//begin
//in_i= {48'h13915D09712F};
//end
//if(i==43)
//begin
//in_i= {48'h08B155134080};
//end
//if(i==44)
//begin
//in_i= {48'h11D0B618211F};
//end
//if(i==45)
//begin
//in_i= {48'h1FA1300FD1BA};
//end
//if(i==46)
//begin
//in_i= {48'h1C623B15515A};
//end
//if(i==47)
//begin
//in_i= {48'h1C5237279188};
//end
//if(i==48)
//begin
//in_i= {48'h2D12052A32AC};
//end
//if(i==49)
//begin
//in_i= {48'h3482E4245300};
//end
//if(i==50)
//begin
//in_i= {48'h2A83732E327C};
//end
//if(i==51)
//begin
//in_i= {48'h2A42C437F2CD};
//end
//if(i==52)
//begin
//in_i= {48'h33426C2CD369};
//end
//if(i==53)
//begin
//in_i= {48'h2AA2E52292C4};
//end
//if(i==54)
//begin
//in_i= {48'h19B2812821E1};
//end
//if(i==55)
//begin
//in_i= {48'h1A415C24D214};
//end
//if(i==56)
//begin
//in_i= {48'h1D913D12B213};
//end
//if(i==57)
//begin
//in_i= {48'h1031A30E610C};
//end
//if(i==58)
//begin
//in_i= {48'h08710F1770A8};
//end
//if(i==59)
//begin
//in_i= {48'h149087131158};
//end
//if(i==60)
//begin
//in_i= {48'h1AA14B0A7167};
//end
//if(i==61)
//begin
//in_i= {48'h13B1F615D0E5};
//end
//if(i==62)
//begin
//in_i= {48'h1A91A224417D};
//end
//if(i==63)
//begin
//in_i= {48'h2CB1DC21028D};
//end
//if(i==64)
//begin
//in_i= {48'h2DF2F821127D};
//end
//if(i==65)
//begin
//in_i= {48'h26E32D30F243};
//end
//if(i==66)
//begin
//in_i= {48'h2F628E36130F};
//end
//if(i==67)
//begin
//in_i= {48'h36B2C82A0376};
//end
//if(i==68)
//begin
//in_i= {48'h2963412872A3};
//end
//if(i==69)
//begin
//in_i= {48'h1E627C2FB239};
//end
//if(i==70)
//begin
//in_i= {48'h2381932572A0};
//end
//if(i==71)
//begin
//in_i= {48'h1FB1CB14922B};
//end
//if(i==72)
//begin
//in_i= {48'h0E71CD16310E};
//end
//if(i==73)
//begin
//in_i= {48'h0C40D91A4109};
//end
//if(i==74)
//begin
//in_i= {48'h17209B0E4185};
//end
//if(i==75)
//begin
//in_i= {48'h14316D091108};
//end
//if(i==76)
//begin
//in_i= {48'h0DA18E1750A7};
//end
//if(i==77)
//begin
//in_i= {48'h1AB1261E518B};
//end
//if(i==78)
//begin
//in_i= {48'h2941D318423F};
//end
//if(i==79)
//begin
//in_i= {48'h2562DE1FF1ED};
//end
//if(i==80)
//begin
//in_i= {48'h2502B831422A};
//end
//if(i==81)
//begin
//in_i= {48'h33826E309333};
//end
//if(i==82)
//begin
//in_i= {48'h360321280343};
//end
//if(i==83)
//begin
//in_i= {48'h27F35F2F1286};
//end
//if(i==84)
//begin
//in_i= {48'h25526C3402AB};
//end
//if(i==85)
//begin
//in_i= {48'h2B51F724E305};
//end
//if(i==86)
//begin
//in_i= {48'h200255199229};
//end
//if(i==87)
//begin
//in_i= {48'h0FD1D81EE143};
//end
//if(i==88)
//begin
//in_i= {48'h1300CC1B318A};
//end
//if(i==89)
//begin
//in_i= {48'h1850E90B6197};
//end
//if(i==90)
//begin
//in_i= {48'h0DE17F0BB0BC};
//end
//if(i==91)
//begin
//in_i= {48'h0B411A1860A9};
//end
//if(i==92)
//begin
//in_i= {48'h1B60DC16B199};
//end
//if(i==93)
//begin
//in_i= {48'h22C1DA11D1C9};
//end
//if(i==94)
//begin
//in_i= {48'h1D028D202171};
//end
//if(i==95)
//begin
//in_i= {48'h24D2332E222A};
//end
//if(i==96)
//begin
//in_i= {48'h34D26A290324};
//end
//if(i==97)
//begin
//in_i= {48'h31C35927B2E0};
//end
//if(i==98)
//begin
//in_i= {48'h27A33F348281};
//end
//if(i==99)
//begin
//in_i= {48'h2D326634631A};
//end
//if((i>10)&&(i[0]==1))
//begin
//$display(test_lpfull.DLY[0].ADD_DELAY.out_delay);
//$display(test_lpfull.DLY[1].ADD_DELAY.out_delay);
//$display(test_lpfull.DLY[2].ADD_DELAY.out_delay);
//$display(test_lpfull.DLY[3].ADD_DELAY.out_delay);
//$display(test_lpfull.DLY[4].ADD_DELAY.out_delay);
//$display(test_lpfull.sample_out[5][35:24]);
//$display(test_lpfull.sample_out[6][35:24]);
//$display(test_lpfull.sample_out[7][35:24]);
//end

if((i>2))
begin
//$display(test_lowampa.DLY[0].ADD_DELAY.out_delay);
//$display(test_lowampa.DLY[1].ADD_DELAY.out_delay);
//$display(test_lowampa.DLY[2].ADD_DELAY.out_delay);
//$display(test_lowampa.DLY[3].ADD_DELAY.out_delay);
end
//if(i%2==1)
//begin
//  $display(out_o[47:36],",",out_o2[47:36]);
//  $display(out_o[35:24],",",out_o2[35:24]);
//  $display(out_o[23:12],",",out_o2[23:12]);
//  $display(out_o[11:0],",",out_o2[11:0]);
//end
//else
//begin
//  $display(out_o[47:36],",",out_o2[95:84]);
//  $display(out_o[35:24],",",out_o2[83:72]);
//  $display(out_o[23:12],",",out_o2[71:60]);
//  $display(out_o[11:0],",",out_o2[59:48]);
//end

if(count0>14'd1000)
begin
  $display(out_o[47:36]);
  $display(out_o[35:24]);
  $display(out_o[23:12]);
  $display(out_o[11:0]);
end
end
 end
     end
`endif


   //////////////////////////////////////////////////////////////////////
   // Tasks (e.g., writing data, etc.)
   //////////////////////////////////////////////////////////////////////   
   
   
   
endmodule

// Local Variables:
// verilog-library-flags:("-y ../hdl/")
// End:
   
