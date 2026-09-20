`timescale 1ns / 1ps
interface apb_if #(
    parameter int ADDR_WIDTH = 8,
    DATA_WIDTH = 32
) (
    input logic PCLK
);
  logic PRESETn, PSEL, PENABLE, PWRITE;
  logic [ADDR_WIDTH-1:0] PADDR;
  logic [DATA_WIDTH-1:0] PWDATA, PRDATA;
  logic PREADY, PSLVERR;
  clocking drv_cb @(negedge PCLK);
    output PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input PRDATA, PREADY, PSLVERR;
  endclocking
endinterface
