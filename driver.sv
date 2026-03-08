class my_driver extends uvm_driver#(my_sequence_item);
    `uvm_component_utils(my_driver)
    virtual axis_if drv_if;

    function new (string name = "my_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(virtual axis_if)::get(this,"","drv_if",drv_if)) begin
            `uvm_fatal("NOVIF", "Could not get drv_if from config db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        drv_if.drv_cb.tvalid <= 1'b0;
        drv_if.drv_cb.tdata  <= 64'b0;
        drv_if.drv_cb.tkeep  <= 8'b0;
        drv_if.drv_cb.tlast  <= 1'b0;
        drv_if.drv_cb.tuser  <= 64'b0;
        
        wait(drv_if.rst_n);
        `uvm_info("DRV", "Reset released, starting drive...", UVM_LOW)
        @(drv_if.drv_cb);
        forever begin
            seq_item_port.get_next_item(req);

            //repeat(item.delay) @(drv_if.drv_cb);

            drv_if.drv_cb.tvalid <= 1'b1;
            drv_if.drv_cb.tdata  <= req.data;
            drv_if.drv_cb.tkeep  <= req.keep;
            drv_if.drv_cb.tlast  <= req.last;
            drv_if.drv_cb.tuser  <= req.user;

            do begin
                @(drv_if.drv_cb); 
            end while (!drv_if.drv_cb.tready);

            drv_if.drv_cb.tvalid <= 1'b0;

            seq_item_port.item_done();
        end
    endtask


endclass
