`timescale 1ns / 1ps
module tb_apb_smoke;
  localparam int ADDR_WIDTH = 8, DATA_WIDTH = 32, WAIT_STATES = 2;
  logic PCLK, PRESETn, PSEL, PENABLE, PWRITE, PREADY, PSLVERR;
  logic [7:0] PADDR;
  logic [31:0] PWDATA, PRDATA;
  int checks = 0;
  initial PCLK = 0;
  always #5 PCLK = ~PCLK;
  apb3_register_slave #(
      .ADDR_WIDTH (ADDR_WIDTH),
      .DATA_WIDTH (DATA_WIDTH),
      .WAIT_STATES(WAIT_STATES)
  ) dut (
      .*
  );
  apb_sva #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sva (
      .PCLK,
      .PRESETn,
      .PSEL,
      .PENABLE,
      .PWRITE,
      .PREADY,
      .PADDR,
      .PWDATA
  );
  task automatic access (input bit wr, input logic [7:0] addr, input logic [31:0] wdata,
                         output logic [31:0] rdata, output bit err);
    int waits = 0;
    @(negedge PCLK);
    PSEL = 1;
    PENABLE = 0;
    PWRITE = wr;
    PADDR = addr;
    PWDATA = wdata;
    @(negedge PCLK);
    PENABLE = 1;
    while (!PREADY) begin
      waits++;
      @(negedge PCLK);
    end
    rdata = PRDATA;
    err   = PSLVERR;
    if (waits != WAIT_STATES) $fatal(1, "wait count expected=%0d got=%0d", WAIT_STATES, waits);
    @(negedge PCLK);
    PSEL = 0;
    PENABLE = 0;
    checks++;
  endtask
  initial begin
    logic [31:0] r;
    bit e;
    PRESETn = 0;
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = 0;
    PWDATA = 0;
    repeat (4) @(posedge PCLK);
    PRESETn = 1;
    for (int i = 0; i < 4; i++) access (1, 8'(i * 4), 32'hCAFE0000 + i, r, e);
    for (int i = 0; i < 4; i++) begin
      access (0, 8'(i * 4), 0, r, e);
      if (e || r !== 32'hCAFE0000 + i) $fatal(1, "read mismatch addr=%0h data=%08h", i * 4, r);
    end
    access (0, 8'h40, 0, r, e);
    if (!e) $fatal(1, "invalid address did not assert PSLVERR");
    access (0, 8'h01, 0, r, e);
    if (!e) $fatal(1, "unaligned address did not assert PSLVERR");
    $display("APB3_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
