`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import apb_uvm_pkg::*;
  logic PCLK = 0;
  always #5ns PCLK = ~PCLK;
  apb_if #(ADDR_WIDTH, DATA_WIDTH) vif (PCLK);
  apb3_register_slave #(
      .ADDR_WIDTH (ADDR_WIDTH),
      .DATA_WIDTH (DATA_WIDTH),
      .WAIT_STATES(WAIT_STATES)
  ) dut (
      .PCLK,
      .PRESETn(vif.PRESETn),
      .PSEL(vif.PSEL),
      .PENABLE(vif.PENABLE),
      .PWRITE(vif.PWRITE),
      .PADDR(vif.PADDR),
      .PWDATA(vif.PWDATA),
      .PRDATA(vif.PRDATA),
      .PREADY(vif.PREADY),
      .PSLVERR(vif.PSLVERR)
  );
  apb_sva #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sva (
      .PCLK,
      .PRESETn(vif.PRESETn),
      .PSEL(vif.PSEL),
      .PENABLE(vif.PENABLE),
      .PWRITE(vif.PWRITE),
      .PREADY(vif.PREADY),
      .PADDR(vif.PADDR),
      .PWDATA(vif.PWDATA)
  );
  initial begin
    vif.PRESETn = 0;
    vif.PSEL = 0;
    vif.PENABLE = 0;
    vif.PWRITE = 0;
    vif.PADDR = '0;
    vif.PWDATA = '0;
    repeat (4) @(posedge PCLK);
    vif.PRESETn = 1;
  end
  initial begin
    uvm_config_db#(virtual apb_if #(ADDR_WIDTH, DATA_WIDTH))::set(null, "uvm_test_top.env.agent.*",
                                                                  "vif", vif);
    run_test("apb_test");
  end
endmodule
