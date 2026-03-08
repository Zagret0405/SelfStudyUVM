class my_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(my_scoreboard)

    uvm_blocking_get_port#(my_sequence_item) exp_port;
    uvm_blocking_get_port#(my_sequence_item) act_port;

    my_sequence_item exp_queue[$];
    
    function new(string name = "my_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        
    endfunction

    function void build_phase(uvm_phase phase);
        exp_port = new("exp_port",this);
        act_port = new("act_port",this);
    endfunction

    task run_phase(uvm_phase phase);
        my_sequence_item exp_item;
        my_sequence_item act_item;
        my_sequence_item temp_item;
        fork
            forever begin
                exp_port.get(exp_item);
                exp_queue.push_back(exp_item);
            end
            
            forever begin
                act_port.get(act_item);
                if(exp_queue.size()>0) begin
                    temp_item = exp_queue.pop_front();
                    if(temp_item.compare(act_item)) begin
                        `uvm_info("MY_SCBD","Compare success!",UVM_LOW);
                    end
                    else begin
                        `uvm_warning("MY_SCBD","Compare Failure!");
                        $display("the expected item is");
                        temp_item.print();
                        $display("the actual item is");
                        act_item.print();
                    end
                end
                else begin
                    `uvm_warning("MY_SCBD","Get DUT data,but without REF_MDL data!");
                end
            end
        join

    endtask

endclass


