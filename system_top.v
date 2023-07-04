`define SIMULATION
`define CSRAM_ADDR_WIDTH 12
module system_top (
    input wire clk_i,
    input wire rst_i,
    input wire uart_rxd,

    output wire uart_txd
);

  parameter CLK_FREQ = 100;
  parameter UART_SPEED = 20;
  parameter GPIO_ADDRESS = 32'hf0000000;
  parameter STS_ADDRESS = 32'hf0000004;


  // dbg_bridge_csram Outputs
  wire [31:0] csram_q;
  wire        csram_dbg_en;
  wire        csram_cen;
  wire        uart_txd_o;
  wire [31:0] csram_addr;
  wire [31:0] csram_d;
  wire [31:0] csram_i;
  wire [ 3:0] csram_wen;

  dbg_bridge_csram #(
      .CLK_FREQ   (CLK_FREQ),
      .UART_SPEED (UART_SPEED),
      .STS_ADDRESS(STS_ADDRESS)
  ) u_dbg_bridge_csram (
      .clk_i     (clk_i),
      .rst_i     (rst_i),
      .uart_rxd_i(uart_rxd),
      .csram_q   (csram_q[31:0]),

      .dma_addr (),
      .dma_write(),
      .dma_wdata(),
      .dma_rdata(),

      .csram_dbg_en(csram_dbg_en),
      .csram_cen   (csram_cen),
      .uart_txd_o  (uart_txd_o),
      .csram_addr  (csram_addr[31:0]),
      .csram_d     (csram_d[31:0]),
      .csram_i     (csram_i[31:0]),
      .csram_wen   (csram_wen[3:0])
  );

  // dma Inputs
  reg  [11:0] dma_addr_i = 0;
  reg         dma_write_i = 0;
  reg  [31:0] dma_wdata_i = 0;
  reg  [31:0] HRDATA_R = 0;

  // dma Outputs
  wire [31:0] dma_rdata_i;
  wire [ 3:0] CS_R;
  wire [ 3:0] WEN_R;
  wire [31:0] HADDR_R;
  wire [ 3:0] CS_W;
  wire [ 3:0] WEN_W;
  wire [31:0] HADDR_W;
  wire [31:0] HWDATA_W;

  dma u_dma (
      .clk_i      (clk_i),
      .rst_i      (rst_i),
      .dma_addr_i (dma_addr_i[11:0]),
      .dma_write_i(dma_write_i),
      .dma_wdata_i(dma_wdata_i[31:0]),
      .HRDATA_R   (HRDATA_R[31:0]),

      .dma_rdata_i(dma_rdata_i[31:0]),
      .CS_R       (CS_R[3:0]),
      .WEN_R      (WEN_R[3:0]),
      .HADDR_R    (HADDR_R[31:0]),
      .CS_W       (CS_W[3:0]),
      .WEN_W      (WEN_W[3:0]),
      .HADDR_W    (HADDR_W[31:0]),
      .HWDATA_W   (HWDATA_W[31:0])
  );

`ifdef SIMULATION

  cmsdk_fpga_sram #(
      // --------------------------------------------------------------------------
      // Parameter Declarations
      // --------------------------------------------------------------------------
      .AW(`CSRAM_ADDR_WIDTH)
  ) u_fpga_ahb2sram_ram2 (
      // Inputs
      .CLK  (clk_i),
      .ADDR (SRAM3ADDR[`CSRAM_ADDR_WIDTH-3:0]),
      .WDATA(SRAM3WDATA),
      .WREN (SRAM3WREN),
      .CS   (~i_SRAM30_cen),

      // Outputs
      .RDATA(i_SRAM30_rdata)
  );

`else

`endif


endmodule
