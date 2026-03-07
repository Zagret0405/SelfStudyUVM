class my_monitor extends uvm_monitor;
    `uvm_component_utils(my_monitor)

    virtual axis_if mon_if;
    
    uvm_analysis_port#(my_sequence_item) ap;

    function new(string name = "my_monitor", uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual axis_if)::get(this,"","mon_if",mon_if)) begin
            `uvm_fatal("NOVIF", "Could not get mon_if from config db")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        wait(mon_if.rst_n);
        `uvm_info("MON", "Reset released, monitor is now active...", UVM_LOW)
        
        forever begin
            my_sequence_item item;
            item = my_sequence_item::type_id::create("item");
            
            @(mon_if.mon_cb);

            if(mon_if.mon_cb.tvalid && mon_if.mon_cb.tready) begin
                item.data = mon_if.mon_cb.tdata;
                item.keep = mon_if.mon_cb.tkeep;
                item.last = mon_if.mon_cb.tlast;
                item.user = mon_if.mon_cb.tuser;
                
                `uvm_info("MON",$sformatf("tdata: %h, tkeep: %h, tlast: %h, tuser: %h, FIFO_count: %d, Full: %b", 
                item.data, item.keep, item.last, item.user, mon_if.mon_cb.axis_wr_data_count, mon_if.mon_cb.prog_full), UVM_LOW)

                ap.write(item);
            
            end
        end
    endtask

endclass
