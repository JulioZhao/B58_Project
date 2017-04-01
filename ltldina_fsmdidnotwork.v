/*
Citation: for the vga setup
http://www.cnblogs.com/spartan/archive/2011/05/05/2038167.html
*/

module ltldina(
	input [9:0] SW,
	input CLOCK_50,
	input[3:0] KEY,
	output VGA_CLK, //should be 25MHz
	output[7:0] VGA_R,
	output[7:0] VGA_G,
	output[7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_SYNC_N, 
	output VGA_HS,
	output VGA_VS,
	output HEX0, HEX1
);
reg[9:0] H_Cont; //行扫描计数器
reg[9:0] V_Cont; //列扫描计数器
reg[7:0] vga_r;
reg[7:0] vga_g;
reg[7:0] vga_b;
reg vga_hs;
reg vga_vs;
reg[10:0] X;
reg[10:0] Y;
reg[7:0]score;
assign VGA_R=vga_r;
assign VGA_G=vga_g;
assign VGA_B=vga_b;
assign VGA_HS=vga_hs;
assign VGA_VS=vga_vs;

hex_decoder h1 (.hex_digit(score[7:4]), .segments(HEX1));
hex_decoder h2 (.hex_decoder(score[3:0]), .segments(HEX2));
//Horizontal Parameter
parameter H_FRONT=16;
parameter H_SYNC=96;
parameter H_BACK=48;
parameter H_ACT=640;
parameter H_BLANK=H_FRONT+H_SYNC+H_BACK;
parameter H_TOTAL=H_FRONT+H_SYNC+H_BACK+H_ACT;
//Vertical Parameter
parameter V_FRONT=11;
parameter V_SYNC=2;
parameter V_BACK=32;
parameter V_ACT=480;
parameter V_BLANK=V_FRONT+V_SYNC+V_BACK;
parameter V_TOTAL=V_FRONT+V_SYNC+V_BACK+V_ACT;


//lalala
wire jump = KEY[1];
parameter d_speed = 10;
parameter s_speed = 5;





wire CLK_25;
wire RST_N;
wire clk;
 
// Generator DAC_CLOCK 25MHz
pll_module pll_inst (
.clock_in ( CLOCK_50 ),
.clock_out ( CLK_25 )
);
//Select DAC CLOCK
assign VGA_CLK=CLK_25;
assign VGA_SYNC_N=1'b0; //If not SOG, Sync input should be tied to 0;
assign VGA_BLANK_N=~((H_Cont<H_BLANK)||(V_Cont<V_BLANK));
assign RST_N=KEY[0];

//Horizontal Generator:Refer to the pixel clock
always@(posedge CLK_25, negedge RST_N)begin
if(!RST_N)
	begin
		H_Cont<=0;
		vga_hs<=1;
		X<=0;
	end
else 
	begin
		if(H_Cont<H_TOTAL)
			H_Cont<=H_Cont+1'b1;
		else
			H_Cont<=0;

			//horizontal Sync
			if(H_Cont==H_FRONT-1) //Front porch end
				vga_hs<=1'b0;
			if(H_Cont==H_FRONT+H_SYNC-1)
				vga_hs<=1'b1;
			//Current X
			if(H_Cont>=H_BLANK)
				X<=H_Cont-H_BLANK;
			else
				X<=0;
	end
end
//vertical Generator: Refer to the horizontal sync
always@(posedge VGA_HS, negedge RST_N)
begin
	if(!RST_N)
		begin
			V_Cont<=0;
			vga_vs<=1;
			Y<=0;
		end
	else 
		begin
			if(V_Cont<V_TOTAL)
				V_Cont<=V_Cont+1'b1;
			else
				V_Cont<=0;
			//Vertical Sync
			if(V_Cont==V_FRONT-1)
				vga_vs<=1'b0;
			if(V_Cont==V_FRONT+V_SYNC-1)
				vga_vs<=1'b1;
			//Current Y
			if(V_Cont>=V_BLANK)
				Y<=V_Cont-V_BLANK;
			else
				Y<=0;
		end
end
 
// declare the square and the floor
reg [9:0] d_up = 300 ;
reg [9:0] d_down = 360;
reg [9:0] d_left = 60;
reg [9:0] d_right = 90;

reg [9:0] s_up = 200;
reg [9:0] s_down = 360;
reg [9:0] s_left = 600;
reg [9:0] s_right = 615;


parameter ceiling = 100;
parameter floor_up = 360;
parameter floor_down = 380;

reg [3:0] cur,next;
localparam A = 4'b0000, B = 4'b0001, C = 4'b0010, D = 4'b0011, E = 4'b0100;

always @(*)
begin: state_table
	case (cur)
		// start
		A: 	begin
				if(!jump) next <= B;
				else next<= A;
			end
		// on the ground
		B: 	begin
				if ((d_right > s_left) && (d_down > s_up)) next <= E;
				else if (d_down == floor_up && !jump) next <= C;
				else next <= B;
			end
		// going up
		C: 	begin
				if ((d_right > s_left) && (d_down > s_up)) next <= E;
				else if (d_up <= ceiling) next <= D;
				else next <= C;				
			end
		// going down
		D:	begin
				if ((d_right > s_left) && (d_down > s_up)) next <= E;
				else if (d_down >= floor_up) next <= B;
				else next <= D;
			end
		// dead
		E:	begin
				if (RST_N == 1'b0) next <= A;
				else next <= E;
			end
	endcase
end

always @(posedge vga_vs)
begin
	if(RST_N == 1'b0) cur<=A;
	else cur<=next;
end

always @(posedge CLK_25, negedge RST_N)
	begin
		if(!RST_N)
			begin
				vga_r <= 0;
				vga_g <= 0;
				vga_b <= 0;
			end
		else
			begin
				vga_r <= (Y >= floor_up && Y <= floor_down) ? 1023:0;
				vga_g <= (Y >= floor_up && Y <= floor_down) ? 1023:0;
				vga_b <= (Y >= floor_up && Y <= floor_down) ? 1023:0;
				if (X >= d_left && X <= d_right && Y >= d_up && Y <= d_down)
					begin
						vga_r <= 1023;
						vga_g <= 0;
						vga_b <= 1023;
					end
				if (X >= s_left && X<= s_right && Y >=s_up && Y<= s_down)
					begin
						vga_r <= 10;
						vga_g <= 1023;
						vga_b <= 10;
					end
			end
	end
	
	
always @(*)
begin
	case (cur)
		// start
		A: 	begin
				// initialize floor, dino, cactus, score
				d_up = 300 ;
				d_down = 360;
				d_left = 60;
				d_right = 90;



				s_up = 200;
				s_down = 360;
				s_left = 600;
				s_right = 615;
				
				score <= 7'd0;
			end
		// on the ground
		B: 	
			begin
				if (s_right >= 0)
					begin
						s_left <= s_left - s_speed;
						s_right <= s_right - s_speed;
					end
				else
					begin
						s_up <= 200;
						s_left <= 600;
						s_right <= 615;
					end
			end
		// going up
		C: 	
			begin
				if (s_right >= 0)
					begin
						s_left <= s_left - s_speed;
						s_right <= s_right - s_speed;
					end
				else
					begin
						s_up <= 200;
						s_left <= 600;
						s_right <= 615;
					end
				d_down <= d_down - d_speed;
				d_up <= d_up - d_speed;			
			end
		// going down
		D:	begin
				if (s_right >= 0)
					begin
						s_left <= s_left - s_speed;
						s_right <= s_right - s_speed;
					end
				else
					begin
						s_up <= 200;
						s_left <= 600;
						s_right <= 615;
					end
				d_down <= d_down + d_speed;
				d_up <= d_up + d_speed;
				score<=score + 1'b1;
			end
		// dead
		E:	begin
                d_up = 0 ;
                d_down = 360;
				d_left = 150;
				d_right = 200;

				s_up = 0;
				s_down = 360;
				s_left = 600;
				s_right = 615;
				// background = "gameover_scene.mif"
			end
	endcase
end


endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule


/* always @(posedge CLK_25, gedge RST_N)
	begin
		if(!RST_N)
			begin
				vga_r <= 0;
				vga_g <= 0;
				vga_b <= 0;
			end
		else
			begin
				vga_r <= (Y >= floor_up && Y <= floor_down) ? 1023:0;
				vga_g <= (Y >= floor_up && Y <= floor_down) ? 1023:0;
				vga_b <= (Y >= floor_up && Y <= floor_down) ? 1023:0;
				if (X >= d_left && X <= d_right && Y >= d_up && Y <= d_down)
					begin
						vga_r <= 1023;
						vga_g <= 0;
						vga_b <= 1023;
					end
				if (X >= s_left && X<= s_right && Y >=s_up && Y<= s_down)
					begin
						vga_r <= 10;
						vga_g <= 1023;
						vga_b <= 10;
					end
			end
	end

always @(posedge vga_vs) 
	begin
		if (!jump && d_up >= 100)
			begin
				d_down <= d_down - jump_speed;
				d_up <= d_up - jump_speed;
			end
		else if (jump && d_down != 360)
			begin 
				d_down <= d_down + jump_speed;
				d_up <= d_up + jump_speed;
			end
		
		if (s_right >= 0)
			begin
				s_left <= s_left - s_speed;
				s_right <= s_right - s_speed;
			end
		else
			begin
				s_up <= rand1;
				s_left <= 600;
				s_right <= 615;
			end
		
	end */
/*
//Pattern Generator
always@(posedge CLK_25, negedge RST_N)
	begin
		if(!RST_N)
			begin
				vga_r<=0;
				vga_g<=0;
				vga_b<=0;
			end
		else 
			begin
				vga_r <= (Y < 120) ? 256 :
				(Y >= 120 && Y < 240) ? 512 :
				(Y >= 240 && Y < 360) ? 768 :
				1023;
 
				vga_g <= (X < 80) ? 128 :
				(X >= 80 && X < 160) ? 256vga_r <= (Y >= 240 && Y <=360) ? 0:1023; :
				(X >= 160 && X < 240) ? 384 :
				(X >= 240 && X < 320) ? 512 :
				(X >= 320 && X < 400) ? 640 :
				(X >= 400 && X < 480) ? 768 :
				(X >= 480 && X < 560) ? 896 :
				1023;

				vga_b <= (Y < 60) ? 1023:
				(Y >= 60 && Y < 120) ? 896 :
				(Y >= 120 && Y < 180) ? 768 :
				(Y >= 180 && Y < 240) ? 640 :
				(Y >= 240 && Y < 300) ? 512 :
				(Y >= 300 && Y < 360) ? 384 :
				(Y >= 360 && Y < 420) ? 256 :
				128;
			end
	end
*/