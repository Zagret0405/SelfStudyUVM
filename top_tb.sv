`timescale 1ns/1ps
`include "uvm_macros.svh"
`include "env.sv"
`include "axis_if.sv"
import uvm_pkg::*;
import my_tb_pkg::*;

module top_tb;
    logic clk;
    logic rst_n;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end
    axis_if in_if(clk,rst_n);
    axis_if out_if(clk,rst_n);
    netifz_udpstack_axis_fifo_64_u64 u_dut (
        .s_axis_aclk          (clk),
        .s_axis_aresetn       (rst_n),

        .s_axis_tvalid        (in_if.tvalid),
        .s_axis_tready        (in_if.tready),
        .s_axis_tdata         (in_if.tdata),
        .s_axis_tkeep         (in_if.tkeep),
        .s_axis_tlast         (in_if.tlast),
        .s_axis_tuser         (in_if.tuser),

        .m_axis_tvalid        (out_if.tvalid),
        .m_axis_tready        (out_if.tready),
        .m_axis_tdata         (out_if.tdata),
        .m_axis_tkeep         (out_if.tkeep),
        .m_axis_tlast         (out_if.tlast),
        .m_axis_tuser         (out_if.tuser),

        
        .axis_wr_data_count   (out_if.axis_wr_data_count),
        .prog_full            (out_if.prog_full)
    );

    assign out_if.tready = 1'b1;

    initial begin
        uvm_config_db#(virtual axis_if)::set(null,"uvm_test_top.env.i_agent.driver","drv_if",in_if);
        uvm_config_db#(virtual axis_if)::set(null,"uvm_test_top.env.i_agent.monitor","mon_if",in_if);
        uvm_config_db#(virtual axis_if)::set(null,"uvm_test_top.env.o_agent.monitor","mon_if",out_if);
        run_test("my_test");
    end

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, top_tb);
    end
     
endmodule