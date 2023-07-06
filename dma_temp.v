module dma (
    //ahb slave signals
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [11:0] dma_addr_i,
    input  wire        dma_write_i,
    input  wire [31:0] dma_wdata_i,
    output wire [31:0] dma_rdata_i,

    //master0 init0
    output reg  [ 3:0] CS_R,
    output reg  [ 3:0] WEN_R,
    output reg  [31:0] HADDR_R,
    input  wire [31:0] HRDATA_R,

    //master1 init1
    output reg [ 3:0] CS_W,
    output reg [ 3:0] WEN_W,
    output reg [31:0] HADDR_W,
    output reg [31:0] HWDATA_W
);

  localparam STATE_IDLE = 2'd0;
  localparam STATE_READ = 2'd1;
  localparam STATE_WRITE = 2'd2;

  //DMA reg
  reg [31:0] reg_rd_addr;
  reg [31:0] reg_wr_addr;
  reg [31:0] reg_length;
  reg [31:0] reg_step;
  reg [31:0] reg_ctrl;

  // source addr  +  target addr  +  length  +  step  + control
  //DMA Control

  wire dma_start = reg_ctrl[0];
  wire [1:0] dma_size = reg_ctrl[5:4];

  always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) reg_rd_addr <= 32'h00000000;
    else begin
      if (dma_write_i & (dma_addr_i == 12'h000)) reg_rd_addr <= dma_wdata_i;
      else reg_rd_addr <= reg_rd_addr;
    end
  end

  always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) reg_wr_addr <= 32'h00000000;
    else begin
      if (dma_write_i & (dma_addr_i == 12'h004)) reg_wr_addr <= dma_wdata_i;
      else reg_wr_addr <= reg_wr_addr;
    end
  end

  always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) reg_length <= 32'h00000000;
    begin
      if (dma_write_i & (dma_addr_i == 12'h008)) reg_length <= dma_wdata_i;
      else reg_length <= reg_length;
    end
  end

  always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) reg_step <= 32'h00000000;
    else begin
      if (dma_write_i & (dma_addr_i == 12'h00C)) reg_step <= dma_wdata_i;
      else reg_step <= reg_step;
    end
  end

  always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) reg_ctrl <= 32'h00000000;
    else begin
      if (dma_write_i & (dma_addr_i == 12'h010)) reg_ctrl <= dma_wdata_i;
      else reg_ctrl <= reg_ctrl_nxt;
    end
  end

  assign reg_ctrl_nxt = {reg_ctrl[31:1], 1'b0};


  //fifo in dma
  dbg_bridge_fifo #(
      .WIDTH (32),
      .DEPTH (8),
      .ADDR_W(3)
  ) u_fifo (
      .clk_i(clk_i),
      .rst_i(rst_i),

      // In
      .push_i(valid_w),
      .data_in_i(fifo_data_i),
      .accept_o(accept_o),

      // Out
      .pop_i(valid_r),
      .data_out_o(fifo_data_o),
      .valid_o(valid_o)
  );


  reg [1:0] state_q, next_state_r;

  always @* begin
    case (state_q)
      STATE_IDLE: begin
        if (dma_start) next_state_r = STATE_READ;
        else next_state_r = STATE_IDLE;
      end
      STATE_READ: begin
      end
      STATE_WRITE: begin
      end
    endcase
  end

  always @(posedge clk_i or negedge rst_i)
    if (!rst_i) state_q <= STATE_IDLE;
    else state_q <= next_state_r;


  // DMA DATA
  reg [31:0] buf_rdata;

  always @(posedge clk_i) begin
    buf_rdata <= HRDATA_R;
  end

  //DMA READ
  reg [31:0] dma_count_rd;  //read count number

  always @(posedge clk_i or negedge rst_i) begin
    if (~rst_i) begin
      dma_count_rd <= 32'h00000000;
      HADDR_R <= 32'h00000000;
    end else begin
      if (dma_start) begin
        dma_count_rd <= reg_length;
        HADDR_R <= reg_rd_addr;
      end else if (dma_count_rd != 32'h00000000) begin
        dma_count_rd <= dma_count_rd - 1'b1;
        HADDR_R <= HADDR_R + reg_step;
      end else begin
        dma_count_rd <= 32'h00000000;
        HADDR_R <= 32'h00000000;
      end
    end
  end
  always @* begin
    WEN_R = 4'b0000;
    case (HADDR_R[11:10])
      2'b00: CS_R = 4'b0001;
      2'b01: CS_R = 4'b0010;
      2'b10: CS_R = 4'b0100;
      2'b11: CS_R = 4'b1000;
    endcase
  end


  //DMA WRITE
  reg        dma_start_wr;
  reg [31:0] dma_count_wr;

  always @(posedge clk_i) begin
    dma_start_wr <= dma_start;
  end

  always @(posedge clk_i or negedge rst_i) begin
    if (~rst_i) begin
      dma_count_wr <= 32'h00000000;
    end else begin
      if (dma_start_wr) begin
        dma_count_wr <= reg_length;
      end else if (dma_count_wr != 32'h00000000) begin
        dma_count_wr <= dma_count_wr - 1'b1;
      end else begin
        dma_count_wr <= dma_count_wr;
      end
    end
  end

  always @(posedge clk_i or negedge rst_i) begin
    if (~rst_i) begin
      WEN_W <= 4'b0000;
      HADDR_W <= 32'h0;
      HWDATA_W <= 32'h0;
    end else begin
      if (dma_start_wr) begin
        WEN_W <= 4'b1111;
        HADDR_W <= reg_wr_addr;
        HWDATA_W <= 32'h0;
      end else if (dma_count_wr != 32'h00000000) begin
        WEN_W <= 4'b1111;
        HADDR_W <= HADDR_W + reg_step;
        HWDATA_W <= buf_rdata;
      end else begin
        WEN_W <= 4'b0000;
        HADDR_W <= 32'h0;
        HWDATA_W <= 32'h0;
      end
    end
  end

  always @* begin
    case (HADDR_W[11:10])
      2'b00: CS_W = 4'b0001;
      2'b01: CS_W = 4'b0010;
      2'b10: CS_W = 4'b0100;
      2'b11: CS_W = 4'b1000;
    endcase
  end

  // assign HWDATA_W = fifo_wr_data;
  assign dma_rdata_i = {32{1'b0}};

endmodule
