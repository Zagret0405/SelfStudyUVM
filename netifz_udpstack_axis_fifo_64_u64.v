`timescale 1ns/1ps

module netifz_udpstack_axis_fifo_64_u64 (
  input  wire          s_axis_aresetn,
  input  wire          s_axis_aclk,
  
  // AXI-Stream Slave (Input)
  input  wire          s_axis_tvalid,
  output wire          s_axis_tready,
  input  wire [63 : 0] s_axis_tdata,
  input  wire [7  : 0] s_axis_tkeep,
  input  wire          s_axis_tlast,
  input  wire [63 : 0] s_axis_tuser,

  // AXI-Stream Master (Output)
  output wire          m_axis_tvalid,
  input  wire          m_axis_tready,
  output wire [63 : 0] m_axis_tdata,
  output wire [7  : 0] m_axis_tkeep,
  output wire          m_axis_tlast,
  output wire [63 : 0] m_axis_tuser,
  
  // Status
  output wire [31 : 0] axis_wr_data_count,
  output wire          prog_full
);

  // =========================================================================
  // 参数与信号定义
  // =========================================================================
  localparam DATA_WIDTH       = 64 + 8 + 1 + 64; // tuser(64) + tlast(1) + tkeep(8) + tdata(64) = 137 bits
  localparam DEPTH            = 2048;
  localparam ADDR_WIDTH       = 11;              // 2^11 = 2048
  localparam PROG_FULL_THRESH = 2000;            // 匹配 C_PROG_FULL_THRESH

  // 数据打包
  wire [DATA_WIDTH-1:0] din;
  assign din = {s_axis_tuser, s_axis_tlast, s_axis_tkeep, s_axis_tdata};

  // RAM定义，并使用属性强制推断Block RAM
  reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];

  // 指针与计数器
  reg [ADDR_WIDTH-1:0] wr_ptr;
  reg [ADDR_WIDTH-1:0] rd_ptr;
  reg [ADDR_WIDTH:0]   ram_count; // 记录目前存放在RAM中的数据量 (最大2048)

  // 标志位
  wire fifo_empty = (ram_count == 0);
  wire fifo_full  = (ram_count == DEPTH);

  // FWFT (First-Word Fall-Through) 寄存器
  reg [DATA_WIDTH-1:0] dout_reg;
  reg                  dout_valid;

  // =========================================================================
  // 读写使能逻辑 (FWFT 适配)
  // =========================================================================
  // 写入RAM：当上游数据有效且FIFO未满
  wire wr_en = s_axis_tvalid && s_axis_tready;
  
  // 读取RAM：如果RAM不为空，且输出寄存器为空或者正在被下游读取，则从RAM读出新数据
  wire rd_en = !fifo_empty && (!dout_valid || m_axis_tready);

  // =========================================================================
  // BRAM 读写和时序控制
  // =========================================================================
  always @(posedge s_axis_aclk) begin
    if (wr_en) begin
      ram[wr_ptr] <= din;
    end
    
    // 同步读取，Vivado会自动推断为BRAM的原生读取输出
    if (rd_en) begin
      dout_reg <= ram[rd_ptr];
    end
  end

  // =========================================================================
  // 状态机与指针控制
  // =========================================================================
  always @(posedge s_axis_aclk) begin
    if (!s_axis_aresetn) begin
      wr_ptr     <= 0;
      rd_ptr     <= 0;
      ram_count  <= 0;
      dout_valid <= 1'b0;
    end else begin
      // 更新读写指针
      if (wr_en) wr_ptr <= wr_ptr + 1;
      if (rd_en) rd_ptr <= rd_ptr + 1;

      // 更新 RAM 中的数据量
      case ({wr_en, rd_en})
        2'b10: ram_count <= ram_count + 1; // 仅写
        2'b01: ram_count <= ram_count - 1; // 仅读
        default: ram_count <= ram_count;   // 同时读写或均不操作
      endcase

      // 更新输出寄存器状态 (FWFT 逻辑)
      if (rd_en) begin
        dout_valid <= 1'b1;        // 有新数据被读入寄存器
      end else if (m_axis_tready) begin
        dout_valid <= 1'b0;        // 寄存器中的数据已被下游取走，且无新数据读入
      end
    end
  end

  // =========================================================================
  // 端口连线
  // =========================================================================
  // AXI-Stream 输出解包
  assign m_axis_tvalid = dout_valid;
  assign {m_axis_tuser, m_axis_tlast, m_axis_tkeep, m_axis_tdata} = dout_reg;

  // 写准备就绪
  assign s_axis_tready = !fifo_full;

  // 状态计算：总数据量 = RAM中的数据量 + FWFT输出寄存器中可能留存的1个数据
  wire [ADDR_WIDTH:0] total_count = ram_count + dout_valid;
  
  // IP核的 axis_wr_data_count 是 32 位的，高位补 0
  assign axis_wr_data_count = { {(32 - (ADDR_WIDTH + 1)){1'b0}}, total_count };
  
  // 触发Prog Full
  assign prog_full = (total_count >= PROG_FULL_THRESH);

endmodule