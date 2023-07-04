module debug_tb;

  logic clk_i, rst_i;
  logic [31:0] data_hex[1023:0];
  logic [7:0] data[1023:0];
  parameter CLK_FREQ = 100;
  parameter UART_SPEED = 20;

  parameter GPIO_ADDRESS = 32'hf0000000;
  parameter STS_ADDRESS = 32'hf0000004;


  initial begin
    clk_i = 0;
    rst_i = 1;
    #20 rst_i = 0;
    #20 rst_i = 1;
  end
  always #5 clk_i = ~clk_i;

  integer file;
  initial begin
    data[0] = 8'h10;
    data[1] = 13;
    data[2] = 0;
    data[3] = 0;
    data[4] = 0;
    data[5] = 1;



    $readmemh("/home/hank/workspace/vivado/CM3/cm3_dma/debug/soc.hex", data_hex);
    for (int i = 6; i < 1024; i++) begin
      data[i] = ((i-6)%4 == 0) ? data_hex[(i-6)/4][31:24] :
        (((i-6)%4 == 1) ? data_hex[(i-6)/4][23:16] :
        (((i-6)%4 == 2) ? data_hex[(i-6)/4][15:8] : data_hex[(i-6)/4][7:0]));
    end

    data[21] = 8'h11;
    data[22] = 13;
    data[23] = 0;
    data[24] = 0;
    data[25] = 0;
    data[26] = 0;
  end

  logic [6:0] count = 0;

  logic [7:0] tx_data_w;
  logic tx_valid_w;
  logic tx_accept_w;
  logic uart_wr_busy_w;
  logic [7:0] uart_wr_data_w;
  logic uart_wr_w;


  //unused
  logic uart_rx_w;
  logic [7:0] uart_rd_data_w;
  logic uart_rd_valid_w;
  logic uart_rx_error_w;
  logic uart_rxd_i;
  logic uart_txd_o;

  always_ff @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
      count <= 0;
      tx_valid_w <= 1'b0;
    end else begin
      tx_data_w <= data[count];
      count <= count + 1;
      tx_valid_w <= 1'b1;
    end
  end


  dbg_bridge_uart #(
      .UART_DIVISOR_W(32)
  ) u_uart (
      .clk_i(clk_i),
      .rst_i(rst_i),

      // Control
      .bit_div_i(CLK_FREQ / UART_SPEED),
      .stop_bits_i(1'b0),  // 0 = 1, 1 = 2

      // Transmit
      .wr_i(uart_wr_w),
      .data_i(uart_wr_data_w),
      .tx_busy_o(uart_wr_busy_w),

      // Receive
      .rd_i(uart_rd_w),
      .data_o(uart_rd_data_w),
      .rx_ready_o(uart_rd_valid_w),

      .rx_err_o(uart_rx_error_w),

      // UART pins
      .rxd_i(uart_rxd_i),
      .txd_o(uart_txd_o)
  );

  //-----------------------------------------------------------------
  // Output FIFO
  //-----------------------------------------------------------------
  wire uart_tx_pop_w = ~uart_wr_busy_w;

  dbg_bridge_fifo #(
      .WIDTH (8),
      .DEPTH (1024),
      .ADDR_W(10)
  ) u_fifo_tx (
      .clk_i(clk_i),
      .rst_i(rst_i),

      // In
      .push_i(tx_valid_w),
      .data_in_i(tx_data_w),
      .accept_o(tx_accept_w),

      // Out
      .pop_i(uart_tx_pop_w),
      .data_out_o(uart_wr_data_w),
      .valid_o(uart_wr_w)
  );



  // dbg_bridge Inputs
  reg         dbg_hready = 1;
  reg  [31:0] dbg_hrdata = 0;
  reg  [31:0] gpio_inputs_i = 0;

  // dbg_bridge Outputs
  wire        dbg_hsel;
  wire        dbg_hwrite;
  wire [31:0] dbg_haddr;
  wire [ 1:0] dbg_hburst;
  wire [31:0] dbg_hwdata;
  wire [ 3:0] dbg_hwuser;
  wire [31:0] gpio_outputs_o;

  // dbg_bridge #(
  //     .CLK_FREQ    (CLK_FREQ),
  //     .UART_SPEED  (UART_SPEED),
  //     .GPIO_ADDRESS(GPIO_ADDRESS),
  //     .STS_ADDRESS (STS_ADDRESS)
  // ) u_dbg_bridge (
  //     .clk_i        (clk_i),
  //     .rst_i        (rst_i),
  //     .uart_rxd_i   (uart_txd_o),
  //     .dbg_hready   (dbg_hready),
  //     .dbg_hrdata   (dbg_hrdata[31:0]),
  //     .gpio_inputs_i(gpio_inputs_i[31:0]),

  //     .dbg_hsel      (dbg_hsel),
  //     .uart_txd_o    (),
  //     .dbg_hwrite    (dbg_hwrite),
  //     .dbg_haddr     (dbg_haddr[31:0]),
  //     .dbg_hburst    (dbg_hburst[1:0]),
  //     .dbg_hwdata    (dbg_hwdata[31:0]),
  //     .dbg_hwuser    (dbg_hwuser[3:0]),
  //     .gpio_outputs_o(gpio_outputs_o[31:0])
  // );


  // fpga_top Outputs
  wire        uart_txd_mcu;
  wire        uart_txd;

  // fpga_top Bidirs
  wire [31:0] GPIO;

  wire        fpga_txd;
  system_top u_top(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .uart_rxd(uart_txd_o),
    .uart_txd(fpga_txd)
  );

  wire [7:0] fpga_tx_data;
  wire rx_ready;
  dbg_bridge_uart #(
      .UART_DIVISOR_W(32)
  ) u_uart_2 (
      .clk_i(clk_i),
      .rst_i(rst_i),

      // Control
      .bit_div_i(CLK_FREQ / UART_SPEED),
      .stop_bits_i(1'b0),  // 0 = 1, 1 = 2

      // Transmit
      .wr_i(),
      .data_i(),
      .tx_busy_o(),

      // Receive
      .rd_i(1'b1),
      .data_o(fpga_tx_data),
      .rx_ready_o(rx_ready),

      .rx_err_o(),

      // UART pins
      .rxd_i(fpga_txd),
      .txd_o()
  );

endmodule
