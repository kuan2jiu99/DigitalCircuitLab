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
    
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= IDLE;
            clk_cnt <= 64'b0;
            prev_cnt <= 64'b0;
            r_start <= 1'b0;
            r_address <= 8'b0;
            timeline <= 64'b0;
            mode <= 16'b0;
        end
        
        else begin
            convertToMin(timeline[63:32], current_min);
            convertToSec(timeline[63:32], current_sec);
            convertToMin(total_time, total_min);
            convertToSec(total_time, total_sec);
            clk_cnt <= clk_cnt + 1'b1;
            
            if (state == IDLE) begin
                mode <= status_para;
                timeline <= time_para;
                
                if (status_para[15:12] == REC_DEFAULT) begin
                    // do nothing
                end
                
                else if (status_para[15:12] == REC_RECORD) begin
                    state <= I_RECORD;
                end
                
                else if (status_para[15:12] == REC_PLAY) begin
                    state <= I_PLAY;
                end
                
                 else if (status_para[15:12] == REC_PAUSE) begin
                    state <= I_PAUSE;
                end
    
                else if (status_para[15:12] == REC_STOP) begin
                    state <= I_STOP;
                end
            end
            
            else if (state == I_PLAY) begin
                start <= 1'b0;
                prev_cnt <= clk_cnt;
                
                if (status_para[15:12] == REC_DEFAULT) begin
                    state <= IDLE;
                end
                
                else if (status_para[15:12] == REC_RECORD) begin
                    state <= S_RECORD;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                else if (status_para[15:12] == REC_PLAY) begin
                    state <= S_PLAY;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                 else if (status_para[15:12] == REC_PAUSE) begin
                    state <= S_PAUSE;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
    
                else if (status_para[15:12] == REC_STOP) begin
                    state <= S_STOP;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
            end
            
            else if (state == S_PLAY) begin
                if (clk_cnt > prev_cnt + 15) begin
                    prev_cnt <= clk_cnt;
                    
                    case(r_address)
                        8'h00: begin
                            if (!busy) begin
                                address <= 8'h00;
                                character <= LETTER_P; // P
                                start <= 1'b1;
                                r_address <= 8'h01;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h01: begin
                            if (!busy) begin
                                address <= 8'h01;
                                character <= LETTER_L; // L
                                start <= 1'b1;
                                r_address <= 8'h02;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h02: begin
                            if (!busy) begin
                                address <= 8'h02;
                                character <= LETTER_A; // L
                                start <= 1'b1;
                                r_address <= 8'h03;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h03: begin
                            if (!busy) begin
                                address <= 8'h03;
                                character <= LETTER_Y; // Y
                                start <= 1'b1;
                                r_address <= 8'h04;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h04: begin
                            if (!busy) begin
                                address <= 8'h04;
                                character <= LETTER_NONE; // _
                                start <= 1'b1;
                                r_address <= 8'h05;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h05: begin
                            if (!busy) begin
                                address <= 8'h05;
                                character <= LETTER_NONE; // _
                                start <= 1'b1;
                                r_address <= 8'h07;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h07: begin
                            if (!busy) begin
                                address <= 8'h07;
                                start <= 1'b1;
                                r_address <= 8'h08;
                                case (current_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h08: begin
                            if(!busy) begin
                                address <= 8'h08;
                                start <= 1'b1;
                                r_address <= 8'h09;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h09: begin
                            if (!busy) begin
                                address <= 8'h09;
                                start <= 1'b1;
                                r_address <= 8'h0A;
                                case (current_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0A: begin
                            if (!busy) begin
                                address <= 8'h0A;
                                start <= 1'b1;
                                r_address <= 8'h0B;
                                case (current_sec)
                                    6'd0, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd1, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd2, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd3, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd4, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd5, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd6, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd7, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd8, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd9, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0B: begin
                            if(!busy) begin
                                address <= 8'h0B;
                                start <= 1'b1;
                                r_address <= 8'h0C;
                                character <= SLASH; // "/"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0C: begin
                            if (!busy) begin
                                address <= 8'h0C;
                                start <= 1'b1;
                                r_address <= 8'h0D;
                                case (total_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end

                        8'h0D: begin
                            if(!busy) begin
                                address <= 8'h0D;
                                start <= 1'b1;
                                r_address <= 8'h0E;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0E: begin
                            if (!busy) begin
                                address <= 8'h0E;
                                start <= 1'b1;
                                r_address <= 8'h0F;
                                case (total_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0F: begin
                            if (!busy) begin
                                address <= 8'h0F;
                                start <= 1'b1;
                                r_address <= 8'h40; // 8'h40
                                case (total_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h40: begin
                            if(!busy) begin
                                address <= 8'h40;
                                start <= 1'b1;
                                r_address <= 8'h41;
                                character <= (mode[5] == 1'b1)? NUM_1: NUM_0; // interpolation 1 or 0.
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h41: begin
                            if(!busy) begin
                                address <= 8'h41;
                                start <= 1'b1;
                                r_address <= 8'h42;
                                character <= LETTER_i; // i
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
    
                        8'h42: begin
                            if(!busy) begin
                                address <= 8'h42;
                                start <= 1'b1;
                                r_address <= 8'h43;
                                character <= (mode[10] == 1'b1)? NUM_1: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h43: begin
                            if(!busy) begin
                                address <= 8'h43;
                                start <= 1'b1;
                                r_address <= 8'h44;
                                character <= (mode[10] == 1'b1)? SLASH: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h44: begin
                            if(!busy) begin
                                address <= 8'h44;
                                start <= 1'b1;
                                r_address <= 8'h45;
                                if (mode[11:10] == 2'b00) begin // normal speed.
                                    character <= NUM_1;
                                end
                                else begin
                                    case(mode[9:6])
                                        4'b0010: character <= NUM_2;
                                        4'b0011: character <= NUM_3;
                                        4'b0100: character <= NUM_4;
                                        4'b0101: character <= NUM_5;
                                        4'b0110: character <= NUM_6;
                                        4'b0111: character <= NUM_7;
                                        4'b1000: character <= NUM_8;
                                        default: character <= NUM_1;
                                    endcase
                                end
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h45: begin
                            if(!busy) begin
                                address <= 8'h45;
                                start <= 1'b1;
                                r_address <= 8'h47;
                                character <= LETTER_x;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h47: begin
                            if(!busy) begin
                                address <= 8'h47;
                                start <= 1'b1;
                                r_address <= 8'h48;
                                character <= LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        // CUBE
                        8'h48: begin
                            if(!busy) begin
                                address <= 8'h48;
                                start <= 1'b1;
                                r_address <= 8'h49;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h49: begin
                            if(!busy) begin
                                address <= 8'h49;
                                start <= 1'b1;
                                r_address <= 8'h4A;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*2)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4A: begin
                            if(!busy) begin
                                address <= 8'h4A;
                                start <= 1'b1;
                                r_address <= 8'h4B;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*3)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4B: begin
                            if(!busy) begin
                                address <= 8'h4B;
                                start <= 1'b1;
                                r_address <= 8'h4C;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*4)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4C: begin
                            if(!busy) begin
                                address <= 8'h4C;
                                start <= 1'b1;
                                r_address <= 8'h4D;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*5)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4D: begin
                            if(!busy) begin
                                address <= 8'h4D;
                                start <= 1'b1;
                                r_address <= 8'h4E;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*6)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4E: begin
                            if(!busy) begin
                                address <= 8'h4E;
                                start <= 1'b1;
                                r_address <= 8'h4F;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*7)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4F: begin
                            if(!busy) begin
                                address <= 8'h4F;
                                start <= 1'b1;
                                state <= I_PLAY;
                                character <= (timeline[63:32] + total_time / 16 >= total_time)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        default: state <= I_PLAY;
                    endcase
                end
            end
            
            else if (state == I_PAUSE) begin
                start <= 1'b0;
                prev_cnt <= clk_cnt;
                
                if (status_para[15:12] == REC_DEFAULT) begin
                    state <= IDLE;
                end
                
                else if (status_para[15:12] == REC_RECORD) begin
                    state <= S_RECORD;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                else if (status_para[15:12] == REC_PLAY) begin
                    state <= S_PLAY;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                 else if (status_para[15:12] == REC_PAUSE) begin
                    state <= S_PAUSE;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
    
                else if (status_para[15:12] == REC_STOP) begin
                    state <= S_STOP;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
            end
            
            else if (state == S_PAUSE) begin
                if (clk_cnt > prev_cnt + 15) begin
                    prev_cnt <= clk_cnt;
                    
                    case(r_address)
                        8'h00: begin
                            if (!busy) begin
                                address <= 8'h00;
                                character <= LETTER_P; // P
                                start <= 1'b1;
                                r_address <= 8'h01;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h01: begin
                            if (!busy) begin
                                address <= 8'h01;
                                character <= LETTER_A; // A
                                start <= 1'b1;
                                r_address <= 8'h02;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h02: begin
                            if (!busy) begin
                                address <= 8'h02;
                                character <= LETTER_U; // L
                                start <= 1'b1;
                                r_address <= 8'h03;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h03: begin
                            if (!busy) begin
                                address <= 8'h03;
                                character <= LETTER_S; // Y
                                start <= 1'b1;
                                r_address <= 8'h04;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h04: begin
                            if (!busy) begin
                                address <= 8'h04;
                                character <= LETTER_E; // E
                                start <= 1'b1;
                                r_address <= 8'h05;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h05: begin
                            if (!busy) begin
                                address <= 8'h05;
                                character <= LETTER_NONE; // _
                                start <= 1'b1;
                                r_address <= 8'h07;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h07: begin
                            if (!busy) begin
                                address <= 8'h07;
                                start <= 1'b1;
                                r_address <= 8'h08;
                                case (current_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h08: begin
                            if(!busy) begin
                                address <= 8'h08;
                                start <= 1'b1;
                                r_address <= 8'h09;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h09: begin
                            if (!busy) begin
                                address <= 8'h09;
                                start <= 1'b1;
                                r_address <= 8'h0A;
                                case (current_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0A: begin
                            if (!busy) begin
                                address <= 8'h0A;
                                start <= 1'b1;
                                r_address <= 8'h0B;
                                case (current_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0B: begin
                            if(!busy) begin
                                address <= 8'h0B;
                                start <= 1'b1;
                                r_address <= 8'h0C;
                                character <= SLASH; // "/"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0C: begin
                            if (!busy) begin
                                address <= 8'h0C;
                                start <= 1'b1;
                                r_address <= 8'h0D;
                                case (total_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end

                        8'h0D: begin
                            if(!busy) begin
                                address <= 8'h0D;
                                start <= 1'b1;
                                r_address <= 8'h0E;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0E: begin
                            if (!busy) begin
                                address <= 8'h0E;
                                start <= 1'b1;
                                r_address <= 8'h0F;
                                case (total_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0F: begin
                            if (!busy) begin
                                address <= 8'h0F;
                                start <= 1'b1;
                                r_address <= 8'h40; // 8'h40
                                case (total_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h40: begin
                            if(!busy) begin
                                address <= 8'h40;
                                start <= 1'b1;
                                r_address <= 8'h41;
                                character <= (mode[5] == 1'b1)? NUM_1: NUM_0; // interpolation 1 or 0.
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h41: begin
                            if(!busy) begin
                                address <= 8'h41;
                                start <= 1'b1;
                                r_address <= 8'h42;
                                character <= LETTER_i; // i
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
    
                        8'h42: begin
                            if(!busy) begin
                                address <= 8'h42;
                                start <= 1'b1;
                                r_address <= 8'h43;
                                character <= (mode[10] == 1'b1)? NUM_1: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h43: begin
                            if(!busy) begin
                                address <= 8'h43;
                                start <= 1'b1;
                                r_address <= 8'h44;
                                character <= (mode[10] == 1'b1)? SLASH: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h44: begin
                            if(!busy) begin
                                address <= 8'h44;
                                start <= 1'b1;
                                r_address <= 8'h45;
                                if (mode[11:10] == 2'b00) begin // normal speed.
                                    character <= NUM_1;
                                end
                                else begin
                                    case(mode[9:6])
                                        4'b0010: character <= NUM_2;
                                        4'b0011: character <= NUM_3;
                                        4'b0100: character <= NUM_4;
                                        4'b0101: character <= NUM_5;
                                        4'b0110: character <= NUM_6;
                                        4'b0111: character <= NUM_7;
                                        4'b1000: character <= NUM_8;
                                        default: character <= NUM_1;
                                    endcase
                                end
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h45: begin
                            if(!busy) begin
                                address <= 8'h45;
                                start <= 1'b1;
                                r_address <= 8'h47;
                                character <= LETTER_x;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h47: begin
                            if(!busy) begin
                                address <= 8'h47;
                                start <= 1'b1;
                                r_address <= 8'h48;
                                character <= LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        // CUBE
                        8'h48: begin
                            if(!busy) begin
                                address <= 8'h48;
                                start <= 1'b1;
                                r_address <= 8'h49;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h49: begin
                            if(!busy) begin
                                address <= 8'h49;
                                start <= 1'b1;
                                r_address <= 8'h4A;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*2)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4A: begin
                            if(!busy) begin
                                address <= 8'h4A;
                                start <= 1'b1;
                                r_address <= 8'h4B;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*3)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4B: begin
                            if(!busy) begin
                                address <= 8'h4B;
                                start <= 1'b1;
                                r_address <= 8'h4C;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*4)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4C: begin
                            if(!busy) begin
                                address <= 8'h4C;
                                start <= 1'b1;
                                r_address <= 8'h4D;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*5)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4D: begin
                            if(!busy) begin
                                address <= 8'h4D;
                                start <= 1'b1;
                                r_address <= 8'h4E;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*6)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4E: begin
                            if(!busy) begin
                                address <= 8'h4E;
                                start <= 1'b1;
                                r_address <= 8'h4F;
                                character <= (timeline[63:32] + total_time / 16 >= total_time / 8*7)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4F: begin
                            if(!busy) begin
                                address <= 8'h4F;
                                start <= 1'b1;
                                state <= I_PLAY;
                                character <= (timeline[63:32] + total_time / 16 >= total_time)? 8'hFF: 8'h20; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        default: state <= I_PAUSE;
                    endcase
                end
            end
            
            else if (state == I_STOP) begin
                start <= 1'b0;
                prev_cnt <= clk_cnt;
                
                if (status_para[15:12] == REC_DEFAULT) begin
                    state <= IDLE;
                end
                
                else if (status_para[15:12] == REC_RECORD) begin
                    state <= S_RECORD;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                else if (status_para[15:12] == REC_PLAY) begin
                    state <= S_PLAY;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                 else if (status_para[15:12] == REC_PAUSE) begin
                    state <= S_PAUSE;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
    
                else if (status_para[15:12] == REC_STOP) begin
                    state <= S_STOP;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
            end
            
            else if (state == S_STOP) begin
                if (clk_cnt > prev_cnt + 15) begin
                    prev_cnt <= clk_cnt;
                    
                    case(r_address)
                        8'h00: begin
                            if (!busy) begin
                                address <= 8'h00;
                                character <= LETTER_S; // S
                                start <= 1'b1;
                                r_address <= 8'h01;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h01: begin
                            if (!busy) begin
                                address <= 8'h01;
                                character <= LETTER_T; // T
                                start <= 1'b1;
                                r_address <= 8'h02;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h02: begin
                            if (!busy) begin
                                address <= 8'h02;
                                character <= LETTER_O; // O
                                start <= 1'b1;
                                r_address <= 8'h03;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h03: begin
                            if (!busy) begin
                                address <= 8'h03;
                                character <= LETTER_P; // P
                                start <= 1'b1;
                                r_address <= 8'h04;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h04: begin
                            if (!busy) begin
                                address <= 8'h04;
                                character <= LETTER_NONE; // _
                                start <= 1'b1;
                                r_address <= 8'h05;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h05: begin
                            if (!busy) begin
                                address <= 8'h05;
                                character <= LETTER_NONE; // _
                                start <= 1'b1;
                                r_address <= 8'h07;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h07: begin
                            if (!busy) begin
                                address <= 8'h07;
                                start <= 1'b1;
                                r_address <= 8'h08;
                                case (current_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h08: begin
                            if(!busy) begin
                                address <= 8'h08;
                                start <= 1'b1;
                                r_address <= 8'h09;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h09: begin
                            if (!busy) begin
                                address <= 8'h09;
                                start <= 1'b1;
                                r_address <= 8'h0A;
                                case (current_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0A: begin
                            if (!busy) begin
                                address <= 8'h0A;
                                start <= 1'b1;
                                r_address <= 8'h0B;
                                case (current_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0B: begin
                            if(!busy) begin
                                address <= 8'h0B;
                                start <= 1'b1;
                                r_address <= 8'h0C;
                                character <= SLASH; // "/"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0C: begin
                            if (!busy) begin
                                address <= 8'h0C;
                                start <= 1'b1;
                                r_address <= 8'h0D;
                                case (total_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end

                        8'h0D: begin
                            if(!busy) begin
                                address <= 8'h0D;
                                start <= 1'b1;
                                r_address <= 8'h0E;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0E: begin
                            if (!busy) begin
                                address <= 8'h0E;
                                start <= 1'b1;
                                r_address <= 8'h0F;
                                case (total_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0F: begin
                            if (!busy) begin
                                address <= 8'h0F;
                                start <= 1'b1;
                                r_address <= 8'h40; // 8'h40
                                case (total_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h40: begin
                            if(!busy) begin
                                address <= 8'h40;
                                start <= 1'b1;
                                r_address <= 8'h41;
                                character <= (mode[5] == 1'b1)? NUM_1: NUM_0; // interpolation 1 or 0.
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h41: begin
                            if(!busy) begin
                                address <= 8'h41;
                                start <= 1'b1;
                                r_address <= 8'h42;
                                character <= LETTER_i; // i
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
    
                        8'h42: begin
                            if(!busy) begin
                                address <= 8'h42;
                                start <= 1'b1;
                                r_address <= 8'h43;
                                character <= (mode[10] == 1'b1)? NUM_1: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h43: begin
                            if(!busy) begin
                                address <= 8'h43;
                                start <= 1'b1;
                                r_address <= 8'h44;
                                character <= (mode[10] == 1'b1)? SLASH: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h44: begin
                            if(!busy) begin
                                address <= 8'h44;
                                start <= 1'b1;
                                r_address <= 8'h45;
                                if (mode[11:10] == 2'b00) begin // normal speed.
                                    character <= NUM_1;
                                end
                                else begin
                                    case(mode[9:6])
                                        4'b0010: character <= NUM_2;
                                        4'b0011: character <= NUM_3;
                                        4'b0100: character <= NUM_4;
                                        4'b0101: character <= NUM_5;
                                        4'b0110: character <= NUM_6;
                                        4'b0111: character <= NUM_7;
                                        4'b1000: character <= NUM_8;
                                        default: character <= NUM_1;
                                    endcase
                                end
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h45: begin
                            if(!busy) begin
                                address <= 8'h45;
                                start <= 1'b1;
                                r_address <= 8'h47;
                                character <= LETTER_x;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h47: begin
                            if(!busy) begin
                                address <= 8'h47;
                                start <= 1'b1;
                                r_address <= 8'h48;
                                character <= LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        // CUBE
                        8'h48: begin
                            if(!busy) begin
                                address <= 8'h48;
                                start <= 1'b1;
                                r_address <= 8'h49;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h49: begin
                            if(!busy) begin
                                address <= 8'h49;
                                start <= 1'b1;
                                r_address <= 8'h4A;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4A: begin
                            if(!busy) begin
                                address <= 8'h4A;
                                start <= 1'b1;
                                r_address <= 8'h4B;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4B: begin
                            if(!busy) begin
                                address <= 8'h4B;
                                start <= 1'b1;
                                r_address <= 8'h4C;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4C: begin
                            if(!busy) begin
                                address <= 8'h4C;
                                start <= 1'b1;
                                r_address <= 8'h4D;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4D: begin
                            if(!busy) begin
                                address <= 8'h4D;
                                start <= 1'b1;
                                r_address <= 8'h4E;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4E: begin
                            if(!busy) begin
                                address <= 8'h4E;
                                start <= 1'b1;
                                r_address <= 8'h4F;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4F: begin
                            if(!busy) begin
                                address <= 8'h4F;
                                start <= 1'b1;
                                state <= I_PLAY;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        default: state <= I_STOP;
                    endcase
                end
            end
            
            else if (state == I_RECORD) begin
                start <= 1'b0;
                prev_cnt <= clk_cnt;
                
                if (status_para[15:12] == REC_DEFAULT) begin
                    state <= IDLE;
                end
                
                else if (status_para[15:12] == REC_RECORD) begin
                    state <= S_RECORD;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                else if (status_para[15:12] == REC_PLAY) begin
                    state <= S_PLAY;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
                
                 else if (status_para[15:12] == REC_PAUSE) begin
                    state <= S_PAUSE;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
    
                else if (status_para[15:12] == REC_STOP) begin
                    state <= S_STOP;
                    mode <= status_para;
                    timeline <= time_para;
                    r_address <= 8'h0;
                end
            end
            
            else if (state == S_RECORD) begin
                if (clk_cnt > prev_cnt + 15) begin
                    prev_cnt <= clk_cnt;
                    
                    case(r_address)
                        8'h00: begin
                            if (!busy) begin
                                address <= 8'h00;
                                character <= LETTER_R; // R
                                start <= 1'b1;
                                r_address <= 8'h01;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h01: begin
                            if (!busy) begin
                                address <= 8'h01;
                                character <= LETTER_E; // E
                                start <= 1'b1;
                                r_address <= 8'h02;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h02: begin
                            if (!busy) begin
                                address <= 8'h02;
                                character <= LETTER_C; // C
                                start <= 1'b1;
                                r_address <= 8'h03;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h03: begin
                            if (!busy) begin
                                address <= 8'h03;
                                character <= LETTER_O; // O
                                start <= 1'b1;
                                r_address <= 8'h04;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h04: begin
                            if (!busy) begin
                                address <= 8'h04;
                                character <= LETTER_R; // R
                                start <= 1'b1;
                                r_address <= 8'h05;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h05: begin
                            if (!busy) begin
                                address <= 8'h05;
                                character <= LETTER_D; // D
                                start <= 1'b1;
                                r_address <= 8'h07;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h07: begin
                            if (!busy) begin
                                address <= 8'h07;
                                start <= 1'b1;
                                r_address <= 8'h08;
                                case (current_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h08: begin
                            if(!busy) begin
                                address <= 8'h08;
                                start <= 1'b1;
                                r_address <= 8'h09;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h09: begin
                            if (!busy) begin
                                address <= 8'h09;
                                start <= 1'b1;
                                r_address <= 8'h0A;
                                case (current_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0A: begin
                            if (!busy) begin
                                address <= 8'h0A;
                                start <= 1'b1;
                                r_address <= 8'h0B;
                                case (current_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0B: begin
                            if(!busy) begin
                                address <= 8'h0B;
                                start <= 1'b1;
                                r_address <= 8'h0C;
                                character <= SLASH; // "/"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0C: begin
                            if (!busy) begin
                                address <= 8'h0C;
                                start <= 1'b1;
                                r_address <= 8'h0D;
                                case (total_min)
                                    4'b0000: character <= NUM_0;
                                    4'b0001: character <= NUM_1;
                                    4'b0010: character <= NUM_2;
                                    4'b0011: character <= NUM_3;
                                    4'b0100: character <= NUM_4;
                                    4'b0101: character <= NUM_5;
                                    4'b0110: character <= NUM_6;
                                    4'b0111: character <= NUM_7;
                                    4'b1000: character <= NUM_8;
                                    4'b1001: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end

                        8'h0D: begin
                            if(!busy) begin
                                address <= 8'h0D;
                                start <= 1'b1;
                                r_address <= 8'h0E;
                                character <= COLON; // ":"
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0E: begin
                            if (!busy) begin
                                address <= 8'h0E;
                                start <= 1'b1;
                                r_address <= 8'h0F;
                                case (total_sec)
                                    6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: character <= NUM_1;
                                    6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: character <= NUM_2;
                                    6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39: character <= NUM_3;
                                    6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: character <= NUM_4;
                                    6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: character <= NUM_5;
                                    
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h0F: begin
                            if (!busy) begin
                                address <= 8'h0F;
                                start <= 1'b1;
                                r_address <= 8'h40; // 8'h40
                                case (total_sec)
                                    6'd00, 6'd10, 6'd20, 6'd30, 6'd40, 6'd50: character <= NUM_0;
                                    6'd01, 6'd11, 6'd21, 6'd31, 6'd41, 6'd51: character <= NUM_1;
                                    6'd02, 6'd12, 6'd22, 6'd32, 6'd42, 6'd52: character <= NUM_2;
                                    6'd03, 6'd13, 6'd23, 6'd33, 6'd43, 6'd53: character <= NUM_3;
                                    6'd04, 6'd14, 6'd24, 6'd34, 6'd44, 6'd54: character <= NUM_4;
                                    6'd05, 6'd15, 6'd25, 6'd35, 6'd45, 6'd55: character <= NUM_5;
                                    6'd06, 6'd16, 6'd26, 6'd36, 6'd46, 6'd56: character <= NUM_6;
                                    6'd07, 6'd17, 6'd27, 6'd37, 6'd47, 6'd57: character <= NUM_7;
                                    6'd08, 6'd18, 6'd28, 6'd38, 6'd48, 6'd58: character <= NUM_8;
                                    6'd09, 6'd19, 6'd29, 6'd39, 6'd49, 6'd59: character <= NUM_9;
                                    default: character <= NUM_0;
                                endcase
                            end
                            
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h40: begin
                            if(!busy) begin
                                address <= 8'h40;
                                start <= 1'b1;
                                r_address <= 8'h41;
                                character <= (mode[5] == 1'b1)? NUM_1: NUM_0; // interpolation 1 or 0.
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h41: begin
                            if(!busy) begin
                                address <= 8'h41;
                                start <= 1'b1;
                                r_address <= 8'h42;
                                character <= LETTER_i; // i
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
    
                        8'h42: begin
                            if(!busy) begin
                                address <= 8'h42;
                                start <= 1'b1;
                                r_address <= 8'h43;
                                character <= (mode[10] == 1'b1)? NUM_1: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h43: begin
                            if(!busy) begin
                                address <= 8'h43;
                                start <= 1'b1;
                                r_address <= 8'h44;
                                character <= (mode[10] == 1'b1)? SLASH: LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h44: begin
                            if(!busy) begin
                                address <= 8'h44;
                                start <= 1'b1;
                                r_address <= 8'h45;
                                if (mode[11:10] == 2'b00) begin // normal speed.
                                    character <= NUM_1;
                                end
                                else begin
                                    case(mode[9:6])
                                        4'b0010: character <= NUM_2;
                                        4'b0011: character <= NUM_3;
                                        4'b0100: character <= NUM_4;
                                        4'b0101: character <= NUM_5;
                                        4'b0110: character <= NUM_6;
                                        4'b0111: character <= NUM_7;
                                        4'b1000: character <= NUM_8;
                                        default: character <= NUM_1;
                                    endcase
                                end
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h45: begin
                            if(!busy) begin
                                address <= 8'h45;
                                start <= 1'b1;
                                r_address <= 8'h47;
                                character <= LETTER_x;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h47: begin
                            if(!busy) begin
                                address <= 8'h47;
                                start <= 1'b1;
                                r_address <= 8'h48;
                                character <= LETTER_NONE;
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        // CUBE
                        8'h48: begin
                            if(!busy) begin
                                address <= 8'h48;
                                start <= 1'b1;
                                r_address <= 8'h49;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h49: begin
                            if(!busy) begin
                                address <= 8'h49;
                                start <= 1'b1;
                                r_address <= 8'h4A;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4A: begin
                            if(!busy) begin
                                address <= 8'h4A;
                                start <= 1'b1;
                                r_address <= 8'h4B;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4B: begin
                            if(!busy) begin
                                address <= 8'h4B;
                                start <= 1'b1;
                                r_address <= 8'h4C;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4C: begin
                            if(!busy) begin
                                address <= 8'h4C;
                                start <= 1'b1;
                                r_address <= 8'h4D;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4D: begin
                            if(!busy) begin
                                address <= 8'h4D;
                                start <= 1'b1;
                                r_address <= 8'h4E;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4E: begin
                            if(!busy) begin
                                address <= 8'h4E;
                                start <= 1'b1;
                                r_address <= 8'h4F;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        8'h4F: begin
                            if(!busy) begin
                                address <= 8'h4F;
                                start <= 1'b1;
                                state <= I_PLAY;
                                character <= 8'hFF; // cube
                            end
                            else begin
                                start <= 1'b0;
                            end
                        end
                        
                        default: state <= I_RECORD;
                    endcase
                end
            end
            
        end
    end
endmodule
                
                    
                        
                        
                        
                        
                        
