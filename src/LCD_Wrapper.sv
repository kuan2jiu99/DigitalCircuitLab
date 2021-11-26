module LCD_Wrapper(
    input i_clk,
    input i_rst,
    input [15:0] status_para,
    input [63:0] time_para,
    input busy,

    output [7:0] character,
    output [7:0] address,
    output start
);
	/*
	 enum {
		I_PLAY,
		S_PLAY,
		I_PAUSE,
		S_PAUSE,
		I_STOP,
		S_STOP,
		I_RECORD,
		S_RECORD,
		IDLE
	} states;
	 */
    localparam I_PLAY = 4'd0;
    localparam S_PLAY = 4'd1;
    localparam I_PAUSE = 4'd2;
    localparam S_PAUSE = 4'd3;
    localparam I_STOP = 4'd4;
    localparam S_STOP = 4'd5;
    localparam I_RECORD = 4'd6;
    localparam S_RECORD = 4'd7;
    localparam IDLE = 4'd8;
    
    localparam REC_DEFAULT = 4'd0;
    localparam REC_RECORD = 4'd4;
    localparam REC_PLAY = 4'd1;
    localparam REC_PAUSE = 4'd2;
    localparam REC_STOP = 4'd3;

    localparam LETTER_A = 8'h41;
    localparam LETTER_B = 8'h42;
    localparam LETTER_C = 8'h43;
    localparam LETTER_D = 8'h44;
    localparam LETTER_E = 8'h45;
    localparam LETTER_F = 8'h46;
    localparam LETTER_G = 8'h47;
    localparam LETTER_H = 8'h48;
    localparam LETTER_I = 8'h49;
    localparam LETTER_J = 8'h4A;
    localparam LETTER_K = 8'h4B;
    localparam LETTER_L = 8'h4C;
    localparam LETTER_M = 8'h4D;
    localparam LETTER_N = 8'h4E;
    localparam LETTER_O = 8'h4F;
    localparam LETTER_P = 8'h50;
    localparam LETTER_Q = 8'h51;
    localparam LETTER_R = 8'h52;
    localparam LETTER_S = 8'h53;
    localparam LETTER_T = 8'h54;
    localparam LETTER_U = 8'h55;
    localparam LETTER_V = 8'h56;
    localparam LETTER_W = 8'h57;
    localparam LETTER_X = 8'h58;
    localparam LETTER_Y = 8'h59;
    localparam LETTER_Z = 8'h5A;
    
    localparam LETTER_a = 8'h61;
    localparam LETTER_b = 8'h62;
    localparam LETTER_c = 8'h63;
    localparam LETTER_d = 8'h64;
    localparam LETTER_e = 8'h65;
    localparam LETTER_f = 8'h66;
    localparam LETTER_g = 8'h67;
    localparam LETTER_h = 8'h68;
    localparam LETTER_i = 8'h69;
    localparam LETTER_j = 8'h6A;
    localparam LETTER_k = 8'h6B;
    localparam LETTER_l = 8'h6C;
    localparam LETTER_m = 8'h6D;
    localparam LETTER_n = 8'h6E;
    localparam LETTER_o = 8'h6F;
    localparam LETTER_p = 8'h70;
    localparam LETTER_q = 8'h71;
    localparam LETTER_r = 8'h72;
    localparam LETTER_s = 8'h73;
    localparam LETTER_t = 8'h74;
    localparam LETTER_u = 8'h75;
    localparam LETTER_v = 8'h76;
    localparam LETTER_w = 8'h77;
    localparam LETTER_x = 8'h78;
    localparam LETTER_y = 8'h79;
    localparam LETTER_z = 8'h7A;
    
    localparam NUM_0 = 8'h30;
    localparam NUM_1 = 8'h31;
    localparam NUM_2 = 8'h32;
    localparam NUM_3 = 8'h33;
    localparam NUM_4 = 8'h34;
    localparam NUM_5 = 8'h35;
    localparam NUM_6 = 8'h36;
    localparam NUM_7 = 8'h37;
    localparam NUM_8 = 8'h38;
    localparam NUM_9 = 8'h39;
    
    localparam COLON = 8'h3A;  // ":"
    localparam SLASH = 8'h2F;  // "/"
    localparam LETTER_NONE = 8'h20;
    
    logic [3:0] state;
    logic r_start;
    logic [15:0] mode;
    logic [63:0] timeline;
    
    logic [63:0] clk_cnt;
    logic [63:0] prev_cnt;
    
    logic [7:0] r_address;
    
    logic [5:0] total_sec;
    logic [5:0] total_min;
    logic [5:0] current_sec;
    logic [5:0] current_min;
    
    logic [31:0] total_time;
    
    task convertToSec;
        input [31:0] i;
        output [5:0] o;
        begin
            o = ((i >> 15) % 60);
        end
    endtask

    task convertToMin;
        input [31:0] i;
        output [5:0] o;
        begin
            o = ((i >> 15) / 60);
        end
    endtask
    
    assign total_time = timeline[31:0];
    
  
