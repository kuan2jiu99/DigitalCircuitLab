module LCD_Controller(
    input i_clk,
    input i_rst,
    input start,
    input [7:0] character,
    input [7:0] address,

    output busy,
    output LCD_EN,
    output LCD_ON,
    output LCD_RW,
    output LCD_RS,
    output LCD_BLON,
    output [7:0] LCD_DATA
);

    localparam WAIT = 3'd1;
    localparam INITIAL = 3'd2;
    localparam ADDRESS_SET = 3'd3;
    localparam CHARACTER_SET = 3'd4;
    localparam IDLE = 3'd5;

    localparam WAIT_CLK = 1500000;
    localparam ENABLE_CYC_TIME = 25;
    localparam ENABLE_PULSE_WIDTH = 30;
    localparam RISE_FALL_TIME = 1;
    localparam ADDR_SET_UP_TIME = 4;
    localparam ADDR_HOLD_TIME = 10;
    localparam DATA_SET_UP_TIME = 4;
    localparam DATA_HOLD_TIME = 22000;
    
    // ADDR_SET_UP_TIME, ENABLE_PULSE_WIDTH, DATA_HOLD_TIME
    logic [2:0] state;
    logic [39:0] clk_cnt;
    logic [39:0] prev_cnt;
    logic [1:0] set_command;
    
    logic [7:0] r_character;
    logic [7:0] r_address;
    logic [7:0] data;
    logic en;
    logic rw;
    logic rs;
    logic busy_signal;
    
    assign LCD_DATA = data;
    assign LCD_RS = rs;
    assign LCD_RW = rw;
    assign LCD_EN = en;
    assign busy = busy_signal;

    // para.
    assign LCD_ON = 1'b1;
    assign LCD_BLON = 1'b1;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= WAIT;
            en <= 1'b1;
            rw <= 1'b0;
            rs <= 1'b0;
            busy_signal <= 1'b1;
            data <= 8'b0011_1111;
            r_address <= 8'b0;
            r_character <= 8'b0;
            clk_cnt <= 40'b0;
            prev_cnt <= 40'b0;
            set_command <= 2'b0;
        end
        
        else if (state == WAIT) begin
            if (clk_cnt >= WAIT_CLK) begin
                state <= INITIAL;
                rs <= 1'b0;
                rw <= 1'b0;
                prev_cnt <= clk_cnt;
            end
				clk_cnt <= clk_cnt + 1'b1;

        end
        
        else if (state == INITIAL) begin
            if (set_command == 2'd0) begin
                data <= 8'b0011_1000;  // command 1.
                rs <= 0;
                rw <= 0;
                clk_cnt <= clk_cnt + 1'd1;
                
                if (clk_cnt >= DATA_HOLD_TIME + ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                    set_command <= 2'd1;
                    rs <= 1'b0;
                    rw <= 1'b1;
                    prev_cnt <= clk_cnt + 1;
                end
                
                else if (clk_cnt >= ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b0;
                end
                
                else if (clk_cnt >= ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b1;
                end
            end
            
            else if (set_command == 2'd1) begin
                data <= 8'b0000_1100;  // command 2.
                rs <= 0;
                rw <= 0;
                clk_cnt <= clk_cnt + 1'd1;
                
                if (clk_cnt >= DATA_HOLD_TIME + ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                    set_command <= 2'd2;
                    rs <= 1'b0;
                    rw <= 1'b1;
                    prev_cnt <= clk_cnt + 1;
                end
                
                else if (clk_cnt >= ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b0;
                end
                
                else if (clk_cnt >= ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b1;
                end
            end
            
            else if (set_command == 2'd2) begin
                data <= 8'b0000_0001;  // command 3.
                rs <= 0;
                rw <= 0;
                clk_cnt <= clk_cnt + 1'd1;
                
                if (clk_cnt >= WAIT_CLK + prev_cnt) begin  // WAIT_CLK
                    set_command <= 2'd3;
                    rs <= 1'b0;
                    rw <= 1'b1;
                    prev_cnt <= clk_cnt + 1;
                end
                
                else if (clk_cnt >= ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b0;
                end
                
                else if (clk_cnt >= ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b1;
                end
            end
            
            else if (set_command == 2'd3) begin
                data <= 8'b0000_0110;  // command 4.
                rs <= 0;
                rw <= 0;
                clk_cnt <= clk_cnt + 1'd1;
                
                if (clk_cnt >= DATA_HOLD_TIME + ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin  // WAIT_CLK
                    set_command <= 2'd0;
                    rs <= 1'b0;
                    rw <= 1'b1;
                    prev_cnt <= clk_cnt + 1;
						  busy_signal <= 1'b0;
						  state <= IDLE;
                end
                
                else if (clk_cnt >= ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b0;
                end
                
                else if (clk_cnt >= ADDR_SET_UP_TIME + prev_cnt) begin
                    en <= 1'b1;
                end
            end
        end
        
        else if (state == ADDRESS_SET) begin
            clk_cnt <= clk_cnt + 1'b1;
            data <= {1'b1, r_address[6:0]};
            rs <= 1'b0;
            rw <= 1'b0;
            
            
            if (clk_cnt >= DATA_HOLD_TIME + ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin  // WAIT_CLK
                state <= CHARACTER_SET;
                rs <= 1'b0;
                rw <= 1'b1;
                prev_cnt <= clk_cnt + 1;
            end
                
            else if (clk_cnt >= ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                en <= 1'b0;
            end
                
            else if (clk_cnt >= ADDR_SET_UP_TIME + prev_cnt) begin
                en <= 1'b1;
            end
        end
        
        else if (state == CHARACTER_SET) begin
            clk_cnt <= clk_cnt + 1'b1;
            data <= r_character;
            rs <= 1'b1;
            rw <= 1'b0;
            
            
            if (clk_cnt >= DATA_HOLD_TIME + ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin  // WAIT_CLK
                state <= IDLE;
                busy_signal <= 1'b0;
                rs <= 1'b0;
                rw <= 1'b1;
                prev_cnt <= clk_cnt + 1;
            end
                
            else if (clk_cnt >= ENABLE_PULSE_WIDTH + ADDR_SET_UP_TIME + prev_cnt) begin
                en <= 1'b0;
            end
                
            else if (clk_cnt >= ADDR_SET_UP_TIME + prev_cnt) begin
                en <= 1'b1;
            end
        end
        
        else if (start & (state == IDLE)) begin
            busy_signal <= 1'b1;
            r_address <= address;
            r_character <= character;
            state <= ADDRESS_SET;
        end
    end
endmodule
        
