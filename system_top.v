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
  parameter STS_ADDRESS = 32'he0000004;
  parameter DMA_ADDRESS = 32'hf0000000;


  // dbg_bridge_csram Outputs
  wire [31:0] csram_q;
  wire        csram_dbg_en;
  wire [ 3:0] csram_cen;
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

      .dma_addr (dma_addr_i),
      .dma_write(dma_write_i),
      .dma_wdata(dma_wdata_i),
      .dma_rdata(dma_rdata_i),

      .csram_dbg_en(csram_dbg_en),
      .csram_cen   (csram_cen),
      .uart_txd_o  (uart_txd_o),
      .csram_addr  (csram_addr[31:0]),
      .csram_d     (csram_d[31:0]),
      .csram_i     (csram_i[31:0]),
      .csram_wen   (csram_wen[3:0])
  );

  // dma Inputs
  wire [31:0] dma_addr_i;
  wire        dma_write_i;
  wire [31:0] dma_wdata_i;
  wire [31:0] HRDATA_R;

  // dma Outputs
  wire [31:0] dma_rdata_i;
  wire [ 3:0] CS_R;
  wire [ 3:0] WEN_R;
  wire read, write;
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

      .READ   (read),
      .CS_R   (CS_R[3:0]),
      .WEN_R  (WEN_R[3:0]),
      .HADDR_R(HADDR_R[31:0]),

      .WRITE   (write),
      .CS_W    (CS_W[3:0]),
      .WEN_W   (WEN_W[3:0]),
      .HADDR_W (HADDR_W[31:0]),
      .HWDATA_W(HWDATA_W[31:0])
  );


  wire [ 9:0] SRAM0_ADDR;
  wire [31:0] SRAM0_WDATA;
  wire [ 3:0] SRAM0_WEN;
  wire        SRAM0_CEN;
  wire [31:0] SRAM0_RDATA;

  wire [ 9:0] SRAM1_ADDR;
  wire [31:0] SRAM1_WDATA;
  wire [ 3:0] SRAM1_WEN;
  wire        SRAM1_CEN;
  wire [31:0] SRAM1_RDATA;

  wire [ 9:0] SRAM2_ADDR;
  wire [31:0] SRAM2_WDATA;
  wire [ 3:0] SRAM2_WEN;
  wire        SRAM2_CEN;
  wire [31:0] SRAM2_RDATA;

  wire [ 9:0] SRAM3_ADDR;
  wire [31:0] SRAM3_WDATA;
  wire [ 3:0] SRAM3_WEN;
  wire        SRAM3_CEN;
  wire [31:0] SRAM3_RDATA;

  assign {SRAM0_ADDR, SRAM0_WDATA, SRAM0_WEN, SRAM0_CEN} = 
            csram_dbg_en ? {csram_addr[9:0], csram_d, csram_wen, csram_cen[0]}:  
            write? {HADDR_W[9:0], HWDATA_W, WEN_W, CS_W[0]} : 
            read ? {HADDR_R[9:0], 32'h0, WEN_R, CS_R[0]}:{10'h000, 32'h0, 4'h0, 1'b0};
  assign {SRAM1_ADDR, SRAM1_WDATA, SRAM1_WEN, SRAM1_CEN} = 
            csram_dbg_en ? {csram_addr[9:0], csram_d, csram_wen, csram_cen[1]}:  
            write? {HADDR_W[9:0], HWDATA_W, WEN_W, CS_W[1]} : 
            read ? {HADDR_R[9:0], 32'h0, WEN_R, CS_R[1]}:{10'h000, 32'h0, 4'h0, 1'b0};
  assign {SRAM2_ADDR, SRAM2_WDATA, SRAM2_WEN, SRAM2_CEN} = 
            csram_dbg_en ? {csram_addr[9:0], csram_d, csram_wen, csram_cen[2]}: 
            write? {HADDR_W[9:0], HWDATA_W, WEN_W, CS_W[2]} :
            read ? {HADDR_R[9:0], 32'h0, WEN_R, CS_R[2]}:  {10'h000, 32'h0, 4'h0, 1'b0};
  assign {SRAM3_ADDR, SRAM3_WDATA, SRAM3_WEN, SRAM3_CEN} = 
            csram_dbg_en ? {csram_addr[9:0], csram_d, csram_wen, csram_cen[3]}:  
            write? {HADDR_W[9:0], HWDATA_W, WEN_W, CS_W[3]} :
            read ? {HADDR_R[9:0], 32'h0, WEN_R, CS_R[3]}: {10'h000, 32'h0, 4'h0, 1'b0};

  assign csram_q = csram_dbg_en ? 
                   (csram_cen[0] ? SRAM0_RDATA : 
                   (csram_cen[1] ? SRAM1_RDATA : 
                   (csram_cen[2] ? SRAM2_RDATA : 
                   (csram_cen[3] ? SRAM3_RDATA : 32'h0)))) : 32'h0;
  assign HRDATA_R =  CS_R[0] ? SRAM0_RDATA : 
                    (CS_R[1] ? SRAM1_RDATA : 
                    (CS_R[2] ? SRAM2_RDATA : 
                    (CS_R[3] ? SRAM3_RDATA : 32'h0)));


`ifdef SIMULATION

  cmsdk_fpga_sram #(
      // --------------------------------------------------------------------------
      // Parameter Declarations
      // --------------------------------------------------------------------------
      .AW(`CSRAM_ADDR_WIDTH)
  ) u_fpga_ahb2sram_ram2 (
      // Inputs
      .CLK  (clk_i),
      .ADDR (SRAM0_ADDR),
      .WDATA(SRAM0_WDATA),
      .WREN (SRAM0_WEN),
      .CS   (SRAM0_CEN),

      // Outputs
      .RDATA(SRAM0_RDATA)
  );

`else

`endif


endmodule
