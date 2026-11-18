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
  // this is basically our fake data memory. using an associative array
  // instead of a real 64k array since we only ever touch a handful of addrs
  bit [15:0] mem[bit [15:0]];

  // the bfm drives the response for request N one loop iteration AFTER we
  // actually captured request N (it's a cycle behind), so we can't just
  // compute the response and send it right away - have to stash it here and
  // send it out next time through the loop
  bit [15:0] next_dout;
  bit        next_complete;
  bit        have_response;
  // pragma uvmf custom class_item_additional end

  function new(string name = "dmem_responder_sequence");
    super.new(name);
  endfunction

  task body();
    req=dmem_transaction::type_id::create("req");
    forever begin
      start_item(req);
      // pragma uvmf custom body begin
      // if we already have a response from last time, load it into req
      // before finish_item so the bfm can drive it out
      if (have_response) begin
        req.Data_dout     = next_dout;
        req.complete_data = next_complete;
      end
      finish_item(req);
      // once finish_item returns, req has been overwritten with whatever
      // the new request is (driver does this under the hood). so now we
      // figure out the response for THIS request, but it doesn't actually
      // go out until the next time we loop back around
      if (req.D_macc) begin
        if (req.Data_rd) begin
          next_dout = mem.exists(req.Data_addr) ? mem[req.Data_addr] : 16'h0000;
        end else begin
          mem[req.Data_addr] = req.Data_din;
          next_dout = 16'h0000;
        end
        next_complete = 1'b1;
        have_response = 1'b1;
      end else begin
        have_response = 1'b0;
      end
      `uvm_info("SEQ",$sformatf("Processed txn: %s",req.convert2string()),UVM_HIGH)
      // pragma uvmf custom body end
    end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

