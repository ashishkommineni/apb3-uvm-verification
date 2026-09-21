`timescale 1ns / 1ps
package apb_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  localparam int ADDR_WIDTH = 8, DATA_WIDTH = 32, WAIT_STATES = 1;
  class apb_item extends uvm_sequence_item;
    rand bit [ADDR_WIDTH-1:0] addr;
    rand bit write;
    rand bit [DATA_WIDTH-1:0] data;
    bit [DATA_WIDTH-1:0] rdata;
    bit slverr;
    int wait_cycles;
    constraint c_addr {
      addr dist {
        [ 0 :  15] := 8,
        [16 : 255] := 2
      };
      addr[1:0] dist {
        0 := 8,
        [1 : 3] := 2
      };
    }
    `uvm_object_utils_begin(apb_item)
      `uvm_field_int(addr, UVM_HEX)
      `uvm_field_int(write, UVM_DEFAULT)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(rdata, UVM_HEX)
      `uvm_field_int(slverr, UVM_DEFAULT)
      `uvm_field_int(wait_cycles, UVM_DEC)
    `uvm_object_utils_end
    function new(string n = "apb_item");
      super.new(n);
    endfunction
  endclass
  class apb_sequencer extends uvm_sequencer #(apb_item);
    `uvm_component_utils(apb_sequencer)
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
  endclass
  class apb_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_driver)
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual apb_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "apb_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.drv_cb.PSEL <= 0;
      vif.drv_cb.PENABLE <= 0;
      vif.drv_cb.PWRITE <= 0;
      vif.drv_cb.PADDR <= '0;
      vif.drv_cb.PWDATA <= '0;
      wait (vif.PRESETn === 1);
      forever begin
        seq_item_port.get_next_item(req);
        vif.drv_cb.PSEL <= 1;
        vif.drv_cb.PENABLE <= 0;
        vif.drv_cb.PWRITE <= req.write;
        vif.drv_cb.PADDR <= req.addr;
        vif.drv_cb.PWDATA <= req.data;
        @(vif.drv_cb);
        vif.drv_cb.PENABLE <= 1;
        do @(vif.drv_cb); while (!vif.drv_cb.PREADY);
        vif.drv_cb.PSEL <= 0;
        vif.drv_cb.PENABLE <= 0;
        seq_item_port.item_done();
      end
    endtask
  endclass
  class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)
    virtual apb_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    uvm_analysis_port #(apb_item) ap;
    function new(string n, uvm_component p);
      super.new(n, p);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual apb_if #(ADDR_WIDTH, DATA_WIDTH))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "apb_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      apb_item tr;
      wait (vif.PRESETn === 1);
      forever begin
        @(posedge vif.PCLK iff (vif.PSEL && !vif.PENABLE));
        tr = apb_item::type_id::create("tr");
        tr.addr = vif.PADDR;
        tr.write = vif.PWRITE;
        tr.data = vif.PWDATA;
        tr.wait_cycles = 0;
        do begin
          @(posedge vif.PCLK);
          if (vif.PSEL && vif.PENABLE && !vif.PREADY) tr.wait_cycles++;
        end while (!vif.PREADY);
        #1ps;
        tr.rdata  = vif.PRDATA;
        tr.slverr = vif.PSLVERR;
        ap.write(tr);
      end
    endtask
  endclass
  class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    apb_sequencer sqr;
    apb_driver drv;
    apb_monitor mon;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      sqr = apb_sequencer::type_id::create("sqr", this);
      drv = apb_driver::type_id::create("drv", this);
      mon = apb_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass
  class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)
    uvm_analysis_imp #(apb_item, apb_scoreboard) analysis_export;
    bit [31:0] model[0:3];
    int checked;
    function new(string n, uvm_component p);
      super.new(n, p);
      analysis_export = new("analysis_export", this);
      foreach (model[i]) model[i] = 0;
    endfunction
    function void write(apb_item tr);
      bit valid = (tr.addr < 16 && tr.addr[1:0] == 0);
      checked++;
      if (tr.slverr !== !valid)
        `uvm_error("RESP", $sformatf("addr=%02h slverr=%0b", tr.addr, tr.slverr))
      if (valid) begin
        if (tr.write) model[tr.addr[3:2]] = tr.data;
        else if (tr.rdata !== model[tr.addr[3:2]])
          `uvm_error("DATA", $sformatf(
                     "addr=%02h expected=%08h got=%08h", tr.addr, model[tr.addr[3:2]], tr.rdata))
      end
    endfunction
    function void check_phase(uvm_phase phase);
      if (checked == 0) `uvm_error("NO_TRAFFIC", "No APB transfers reached the scoreboard")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("APB_SUMMARY", $sformatf("Checked %0d transfers", checked), UVM_LOW)
    endfunction
  endclass
  class apb_coverage extends uvm_subscriber #(apb_item);
    `uvm_component_utils(apb_coverage)
    apb_item tr;
    covergroup cg;
      cp_dir: coverpoint tr.write;
      cp_addr: coverpoint tr.addr {bins regs[] = {0, 4, 8, 12}; bins invalid = default;}
      cp_wait: coverpoint tr.wait_cycles {bins zero = {0}; bins waited = {[1 : 10]};}
      cp_err: coverpoint tr.slverr;
      cx: cross cp_dir, cp_addr;
    endgroup
    function new(string n, uvm_component p);
      super.new(n, p);
      cg = new();
    endfunction
    function void write(apb_item t);
      tr = t;
      cg.sample();
    endfunction
  endclass
  class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)
    apb_agent agent;
    apb_scoreboard sb;
    apb_coverage cov;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      agent = apb_agent::type_id::create("agent", this);
      sb = apb_scoreboard::type_id::create("sb", this);
      cov = apb_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass
  class apb_sequence extends uvm_sequence #(apb_item);
    `uvm_object_utils(apb_sequence)
    function new(string n = "apb_sequence");
      super.new(n);
    endfunction
    task body();
      for (int i = 0; i < 4; i++) begin
        req = apb_item::type_id::create("wr");
        start_item(req);
        req.addr  = i * 4;
        req.write = 1;
        req.data  = 32'h1000 + i;
        finish_item(req);
      end
      for (int i = 0; i < 4; i++) begin
        req = apb_item::type_id::create("rd");
        start_item(req);
        req.addr  = i * 4;
        req.write = 0;
        req.data  = 0;
        finish_item(req);
      end
      req = apb_item::type_id::create("misaligned");
      start_item(req);
      req.addr  = 1;
      req.write = 0;
      req.data  = 0;
      finish_item(req);
      req = apb_item::type_id::create("decode_error");
      start_item(req);
      req.addr  = 8'h40;
      req.write = 0;
      req.data  = 0;
      finish_item(req);
      repeat (80) begin
        req = apb_item::type_id::create("rand");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "randomization failed")
        finish_item(req);
      end
    endtask
  endclass
  class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)
    apb_env env;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      env = apb_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      apb_sequence seq;
      phase.raise_objection(this);
      seq = apb_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      repeat (4) @(posedge env.agent.mon.vif.PCLK);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
