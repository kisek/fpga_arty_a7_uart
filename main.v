/** main.v for Arty A7 FPGA Board      ArchLab, Institute of Science Tokyo / Tokyo Tech **/
/*****************************************************************************************/
`default_nettype none

`define UART_CNT 100  // UART TX wait count, 100MHz / 100 = 1Mbaud
/*****************************************************************************************/
module m_uart_tx (
    input wire       w_clk,     // 100MHz clock signal
    input wire       w_we,      // write enable
    input wire [7:0] w_din,     // data in
    output wire      w_uart_tx  // UART tx, data line from FPGA to PC
);
    reg [8:0] r_buf = 9'b1_1111_1111;
    reg [7:0] r_cnt = 1;
    always @(posedge w_clk) begin
        r_cnt <= (w_we) ? 1 : (r_cnt==`UART_CNT) ? 1 : r_cnt + 1;
        r_buf <= (w_we) ? {w_din, 1'b0} : (r_cnt==`UART_CNT) ? {1'b1, r_buf[8:1]} : r_buf;
    end
    assign w_uart_tx = r_buf[0];
endmodule

/*****************************************************************************************/
module m_main (
    input  wire  w_clk,       // 100MHz clock signal
    input  wire  w_uart_rx,   // UART rx, data line from PC to FPGA
    output wire  w_uart_tx,   // UART tx, data line from FPGA to PC
    output wire  [3:0] w_led  // LED
);
    reg [31:0] r_cnt = 0;
    always @(posedge w_clk) r_cnt <= r_cnt + 1;
    assign w_led = r_cnt[26:23];
    
    reg r_we = 0;
    always @(posedge w_clk) r_we <= (r_cnt[23:0]==0);
    m_uart_tx m0 (w_clk, r_we, 8'h61, w_uart_tx); // 8'h61 for 'a'
endmodule
/*****************************************************************************************/
