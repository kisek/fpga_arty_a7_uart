/** main.v for Arty A7 FPGA Board      ArchLab, Institute of Science Tokyo / Tokyo Tech **/
/*****************************************************************************************/
`default_nettype none

`define UART_CNT 100  // UART wait count, 100MHz / 100 = 1Mbaud
/*****************************************************************************************/
module m_uart_tx (
    input  wire       w_clk,     // 100MHz clock signal
    input  wire       w_we,      // write enable
    input  wire [7:0] w_din,     // data in
    output wire       w_uart_tx  // UART tx, data line from FPGA to PC
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
module m_uart_rx (
    input  wire       w_clk,   // 100MHz clock signal
    input  wire       w_rxd,   // UART rx, data line from PC to FPGA
    output wire [7:0] w_char,  // 8-bit data received
    output reg        r_en = 0 // data enable
);
    reg [2:0] r_detect_cnt = 0; /* to detect the start bit */
    always @(posedge w_clk) r_detect_cnt <= (w_rxd) ? 0 : r_detect_cnt + 1;
    wire w_detected = (r_detect_cnt>2);
    
    reg       r_busy = 0; // r_busy is set while receiving 9-bits data
    reg [3:0] r_bit  = 0; // the number of received bits
    reg [7:0] r_cnt  = 0; // wait count for 1Mbaud
    always@(posedge w_clk) r_cnt <= (r_busy==0) ? 1 : (r_cnt==`UART_CNT) ? 1 : r_cnt + 1;
    
    reg [8:0] r_data = 0;
    always@(posedge w_clk) begin
        if (r_busy==0) begin
            {r_data, r_bit, r_en} <= 0;
            if (w_detected) r_busy <= 1;
        end
        else if (r_cnt>= `UART_CNT) begin
            r_bit <= r_bit + 1;
            r_data <= {w_rxd, r_data[8:1]};
            if (r_bit==8) begin r_en <= 1; r_busy <= 0; end
        end
    end
    assign w_char = r_data[7:0];
endmodule

/*****************************************************************************************/
module m_main (
    input  wire  w_clk,       // 100MHz clock signal
    input  wire  w_uart_rx,   // UART rx, data line from PC -> FPGA
    output wire  w_uart_tx,   // UART tx, data line from FPGA -> PC
    output wire  [3:0] w_led  // LED
);
    reg [31:0] r_cnt = 0;
    always @(posedge w_clk) r_cnt <= r_cnt + 1;
    assign w_led = r_cnt[26:23];
    
    reg r_we = 0;
    always @(posedge w_clk) r_we <= (r_cnt[23:0]==0);
    
    wire w_en;
    wire [7:0] w_char;
    reg  [7:0] r_char = 8'h61;  // 8'h61 for 'a'
    m_uart_rx m1 (w_clk, w_uart_rx, w_char, w_en);
    always @(posedge w_clk) if (w_en) r_char <= w_char;
    
    m_uart_tx m2 (w_clk, r_we, r_char, w_uart_tx);
endmodule
/*****************************************************************************************/
