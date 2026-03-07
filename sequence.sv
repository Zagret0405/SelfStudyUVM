class my_sequence_item extends uvm_sequence_item;
    rand bit [63:0] data;
    rand bit [7:0] keep;
    rand bit last;
    rand bit [63:0] user;

    rand int delay;

    `uvm_object_utils_begin(my_sequence_item)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(keep, UVM_ALL_ON)
        `uvm_field_int(last, UVM_ALL_ON)
        `uvm_field_int(user, UVM_ALL_ON)
    `uvm_object_utils_end

    constraint c_keep { keep == 8'b11111111; }
    constraint c_delay { delay inside {[0:5]}; }

    function new(string name = "my_sequence_item");
        super.new(name);
    endfunction

endclass

class basic_sequence extends uvm_sequence#(my_sequence_item);
    `uvm_object_utils(basic_sequence)

    function new(string name = "basic_sequence");
        super.new(name);
    endfunction

    virtual task body();
        if (starting_phase != null) 
            starting_phase.raise_objection(this);
    
        if (starting_phase != null) 
            starting_phase.drop_objection(this);
    endtask
    
endclass

class my_sequence extends basic_sequence;
    `uvm_object_utils(my_sequence)

    function new(string name = "my_sequence");
        super.new(name);
    endfunction

    virtual task body();
        my_sequence_item item;
        for (int i = 0; i < 10; i++) begin
            item = my_sequence_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                if(i==9) last == 1;
                else last == 0;
            }) begin
                `uvm_error("MY_SEQUENCE", "Randomize failed.");
            end
            `uvm_info("MY_SEQUENCE", $sformatf("data: %h, keep: %h, last: %b, user: %h, delay: %d", item.data, item.keep, item.last, item.user, item.delay), UVM_LOW);
            finish_item(item);
        end
    endtask
    
endclass
