package my_tb_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    `include "sequence.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "reference_model.sv"
    `include "scoreboard.sv"
class my_agent extends uvm_agent;
    `uvm_component_utils(my_agent)
    
    my_driver driver;
    my_monitor monitor;
    uvm_sequencer#(my_sequence_item) sequencer;
    uvm_analysis_port#(my_sequence_item) ap;

    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        monitor = my_monitor::type_id::create("monitor", this);
        if(is_active == UVM_ACTIVE) begin
            driver = my_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer#(my_sequence_item)::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if(is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        ap = monitor.ap;
    endfunction

    task run_phase(uvm_phase phase);
        if(is_active == UVM_ACTIVE) begin
            phase.raise_objection(this);
            begin
                my_sequence seq;
                seq = my_sequence::type_id::create("seq");
                seq.start(sequencer);
            end
            phase.drop_objection(this);
        end
    endtask

endclass

class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    my_agent i_agent;
    my_agent o_agent;
    my_model ref_model;
    my_scoreboard scoreboard;
    uvm_tlm_analysis_fifo#(my_sequence_item) i_ref_fifo;
    uvm_tlm_analysis_fifo#(my_sequence_item) ref_sb_fifo;
    uvm_tlm_analysis_fifo#(my_sequence_item) o_ref_fifo;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        i_agent = my_agent::type_id::create("i_agent", this);
        o_agent = my_agent::type_id::create("o_agent", this);
        i_agent.is_active = UVM_ACTIVE;
        o_agent.is_active = UVM_PASSIVE;
        ref_model = my_model::type_id::create("ref_model", this);
        i_ref_fifo = new("i_ref_fifo", this);
        ref_sb_fifo = new("ref_sb_fifo", this);
        o_ref_fifo = new("o_ref_fifo", this);
        scoreboard = my_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        i_agent.ap.connect(i_ref_fifo.analysis_export);
        ref_model.port.connect(i_ref_fifo.blocking_get_export);
        ref_model.ap.connect(ref_sb_fifo.analysis_export);
        scoreboard.exp_port.connect(ref_sb_fifo.blocking_get_export);
        o_agent.ap.connect(o_ref_fifo.analysis_export);
        scoreboard.act_port.connect(o_ref_fifo.blocking_get_export);
    endfunction

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
    
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    
        `uvm_info("UVM_TREE", "Printing UVM Topology...", UVM_LOW)
        uvm_top.print_topology();
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