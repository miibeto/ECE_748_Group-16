//----------------------------------------------------------------------
// Created with uvmf_gen version 2026.1
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class can be used to provide stimulus when an interface
//              has been configured to run in a responder mode. It
//              will never finish by default, always going back to the driver
//              and driver BFM for the next transaction with which to respond.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class dmem_responder_sequence 
  extends dmem_sequence_base ;

  `uvm_object_utils( dmem_responder_sequence )

  // pragma uvmf custom class_item_additional begin
  //16-bit word-addressable memory indexed by 16-bit lc3 addresses
  bit [15:0] memory [bit [15:0]];
  // pragma uvmf custom class_item_additional end

  function new(string name = "dmem_responder_sequence");
    super.new(name);
  endfunction

  task body();
    req=dmem_transaction::type_id::create("req");
    req.Data_dout=16'h0000;
    req.complete_data=1'b0;
    forever begin
      start_item(req);
      finish_item(req);
      //the driver has returned a memory access request for this address
      if (req.D_macc) begin
        if (req.Data_rd) begin
          if (memory.exists(req.Data_addr))
            req.Data_dout=memory[req.Data_addr];
          else
            req.Data_dout=16'h0000;
          `uvm_info("DMEM", $sformatf("read addr=%04h data=%04h",req.Data_addr,req.Data_dout), UVM_MEDIUM)
        end else begin
          memory[req.Data_addr]=req.Data_din;
          req.Data_dout=16'h0000;
          `uvm_info("DMEM", $sformatf("write addr=%04h data=%04h",req.Data_addr,req.Data_din), UVM_MEDIUM)
        end
        req.complete_data=1'b1;
      end else begin
        req.complete_data=1'b0;
      end
    end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

