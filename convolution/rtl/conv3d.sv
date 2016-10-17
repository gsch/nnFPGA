//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
`timescale 1ns/1ps

module conv3d import functions_pkg::clog2; # (
   parameter FRAME_H_MAX   = 224,
   parameter FRAME_W_MAX   = 224,
   parameter DIN_WIDTH     = 8,
   parameter DOUT_WIDTH    = 8,
   parameter KERN_WIDTH    = 16,
   parameter WIN_SIZE      = 3,
   parameter CHANNELS_IN   = 4,
   parameter CHANNELS_OUT  = 128
) (
   //external buffer
   input    wire [CHANNELS_IN-1:0][WIN_SIZE-1:0][WIN_SIZE-1:0][KERN_WIDTH-1:0] kernel[CHANNELS_OUT],

   //external buffer
   input    wire [clog2(FRAME_H_MAX):0] frame_h,
   input    wire [clog2(FRAME_W_MAX):0] frame_w,

   input    wire                                      clk,
   input    wire                                      reset_n,
   input    wire                                      frame_start,
   input    wire                                      din_vld[CHANNELS_OUT],
   input    wire [ CHANNELS_IN-1:0][ DIN_WIDTH-1:0]   din[CHANNELS_OUT],
   output   wire                                      dout_vld[CHANNELS_OUT],
   output   wire                   [DOUT_WIDTH-1:0]   dout[CHANNELS_OUT]
);
   genvar g;
   generate
      for (g = 0; g < CHANNELS_OUT; g++) begin: ch_out
         wire                                                                   frame_start_buf;
         wire                                                                   din_vld_buf;
         wire                   [CHANNELS_IN-1:0][WIN_SIZE-1:0][DIN_WIDTH-1:0]  din_buf;
         wire                                                                   win_vld;
         wire  [CHANNELS_IN-1:0][   WIN_SIZE-1:0][WIN_SIZE-1:0][DIN_WIDTH-1:0]  window;

         row_buffer # (
            .FRAME_H_MAX      (FRAME_H_MAX),
            .FRAME_W_MAX      (FRAME_W_MAX),
            .DIN_WIDTH        (DIN_WIDTH),
            .WIN_SIZE         (WIN_SIZE),
            .CH_NUM           (CHANNELS_IN)
         ) row_buffer_inst (
            .clk,
            .reset_n,
            .frame_h,
            .frame_w,
            .frame_start,
            .din_vld          (din_vld[g]),
            .din              (din[g]),
            .din_vld_buf,
            .din_buf,
            .frame_start_buf
         );

         win_pad # (
            .FRAME_H_MAX   (FRAME_H_MAX),
            .FRAME_W_MAX   (FRAME_W_MAX),
            .DIN_WIDTH     (DIN_WIDTH),
            .FRAME_H       (FRAME_H),
            .FRAME_W       (FRAME_W),
            .WIN_SIZE      (WIN_SIZE),
            .CH_NUM        (CHANNELS_IN)
         ) win_pad_inst (
            .clk,
            .reset_n,
            .frame_h,
            .frame_w,
            .frame_start   (frame_start_buf),
            .din_vld       (din_vld_buf),
            .din           (din_buf),
            .win_vld,
            .window
         );

         conv3d_kernel # (
            .KERN_WIDTH (KERN_WIDTH),
            .DIN_WIDTH  (DIN_WIDTH),
            .DOUT_WIDTH (DOUT_WIDTH),
            .KERN_H     (WIN_SIZE),
            .KERN_W     (WIN_SIZE),
            .KERN_L     (CHANNELS_IN)
         ) conv3d_kernel_inst (
            .clk,
            .reset_n,
            .kernel     (kernel[g]),
            .din_vld    (win_vld),
            .din        (window),
            .dout_vld   (dout_vld[g]),
            .dout       (dout[g])
         );
      end: ch_out
   endgenerate
endmodule: conv3d