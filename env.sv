package my_tb_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    `include "sequence.sv"
    `include "driver.sv"
    `include "monitor.sv"
class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    //my_agent agent;

    my_driver driver;
    my_monitor monitor;
    uvm_sequencer#(my_sequence_item) sequencer;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        driver = my_driver::type_id::create("driver", this);
        monitor = my_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(my_sequence_item)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        begin
            my_sequence seq;
            seq = my_sequence::type_id::create("seq");
            seq.start(sequencer);
        end
        phase.drop_objection(this);
    endtask
endclass

class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    my_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env = my_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("TEST", "Starting sequence in run_phase...", UVM_LOW)
        #10;
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("TEST", "Test finished!", UVM_LOW)
    endfunction
endclass

endpackage