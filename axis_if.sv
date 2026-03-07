interface axis_if(input logic clk, input logic rst_n);
    logic        tvalid;
    logic        tready;
    logic [63:0] tdata;
    logic [7:0]  tkeep;
    logic        tlast;
    logic [63:0] tuser;

    logic [31 : 0] axis_wr_data_count;
    logic prog_full;

    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;
        output tvalid;
        output tdata;
        output tkeep;
        output tlast;
        output tuser;
        input tready;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input tvalid;
        input tdata;
        input tkeep;
        input tlast;
        input tuser;
        input tready;

        input axis_wr_data_count;
        input prog_full;
    endclocking

    modport DRV(clocking drv_cb, input clk, rst_n);
    modport MON(clocking mon_cb, input clk, rst_n);


endinterface
