`timescale 1ns / 1ps
module apb_sva #(
    parameter int ADDR_WIDTH = 8,
    DATA_WIDTH = 32
) (
    input logic PCLK,
    PRESETn,
    PSEL,
    PENABLE,
    PWRITE,
    PREADY,
    input logic [ADDR_WIDTH-1:0] PADDR,
    input logic [DATA_WIDTH-1:0] PWDATA
);
  default clocking cb @(posedge PCLK);
  endclocking
  default disable iff (!PRESETn); ap_enable_requires_select :
  assert property (PENABLE |-> PSEL);
  ap_setup_to_access :
  assert property ((PSEL && !PENABLE) |=> PSEL && PENABLE);
  ap_control_stable_wait :
  assert property ((PSEL && PENABLE && !PREADY) |=> $stable({PADDR, PWRITE, PWDATA}));
  cp_read :
  cover property (PSEL && PENABLE && PREADY && !PWRITE);
  cp_write :
  cover property (PSEL && PENABLE && PREADY && PWRITE);
endmodule
