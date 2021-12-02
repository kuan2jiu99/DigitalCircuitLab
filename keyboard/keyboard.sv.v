module keyboard(
clk,     // global clock
rst_n,   // low active reset
PS2_CLK,
PS2_DATA,
key_num
    );
 
input rst_n;
input clk;
inout PS2_DATA;
inout PS2_CLK;

// keyboard output.
output [3:0] key_num;

// Keyboard Decode
wire [511:0] key_down;
wire [8:0] last_change;
wire key_valid;

// Binary to 7-seg Decoder
wire [3:0] display_num;
    
KeyboardDecoder Ukeyboard_dec(
.key_down(key_down),  // the key that is currently being pressed
.last_change(last_change),  // the previous pressed key
.key_valid(key_valid),  // one pulse when the moment pressed or released
.PS2_DATA(PS2_DATA),
.PS2_CLK(PS2_CLK),
.rst(~rst_n),           // high active reset
.clk(clk)
    );
    
output_control output_controller (
.last_change(last_change),
.key_num(keynum)
); 
    
endmodule