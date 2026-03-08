class my_model extends uvm_component;
    `uvm_component_utils(my_model)

    uvm_blocking_get_port#(my_sequence_item) port;
    uvm_analysis_port#(my_sequence_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        port = new("port", this);
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        my_sequence_item item;
        my_sequence_item item_cp;
        forever begin
            port.get(item);
            item_cp = new("item_cp");
            item_cp.copy(item);
            `uvm_info("REF_MODEL","start copy!",UVM_LOW);
            ap.write(item_cp);
        end
    endtask
endclass