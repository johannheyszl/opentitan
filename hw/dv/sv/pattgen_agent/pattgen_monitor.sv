// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class pattgen_monitor extends dv_base_monitor #(
    .ITEM_T (pattgen_item),
    .CFG_T  (pattgen_agent_cfg),
    .COV_T  (pattgen_agent_cov)
  );
  `uvm_component_utils(pattgen_monitor)
  `uvm_component_new

  bit reset_asserted = 1'b0;

  // analysis ports connected to scb
  uvm_analysis_port #(pattgen_item) item_port[NUM_PATTGEN_CHANNELS];

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    for (uint i = 0; i < NUM_PATTGEN_CHANNELS; i++) begin
      item_port[i] = new($sformatf("item_port[%0d]", i), this);
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    wait(cfg.vif.rst_ni);
    collect_trans();
  endtask : run_phase

  virtual protected task collect_trans();
    for (uint i = 0; i < NUM_PATTGEN_CHANNELS; i++) begin
      fork
        automatic uint channel = i;
        collect_channel_trans(channel);
        reset_thread();
        mon_pcl(channel);
      join_none
    end
  endtask : collect_trans

  virtual task collect_channel_trans(uint channel);
    bit  bit_data;
    uint bit_cnt;

    pattgen_item dut_item;
    forever begin
      wait(cfg.en_monitor);
      dut_item = pattgen_item::type_id::create("dut_item");
      bit_cnt = 0;
      `uvm_info(`gfn, $sformatf("PATTGEN_MON%d start: bit_cnt:%0d  len:%0d",
                                channel, bit_cnt, cfg.length[channel]), UVM_MEDIUM)
      fork
        begin : isolation_thread
          fork
            // capture pattern bits
            begin
              do begin
                wait(cfg.vif.rst_ni);
                get_pattgen_bit(channel, bit_data);
                `uvm_info(`gfn, $sformatf("\n--> monitor: channel %0d, polar %b, data[%0d] %b",
                                          channel, cfg.polarity[channel], bit_cnt, bit_data),
                          UVM_HIGH)
                dut_item.data_q.push_back(bit_data);
                bit_cnt++;
              end while (bit_cnt < cfg.length[channel]);
              // must see the channel_done intr is asserted because reset can be issued
              // immediately right after the last bit
              wait(cfg.channel_done[channel]);
              // avoid race condition (counter is achieved and reset is issued at the same time)
              if (!reset_asserted && !cfg.error_injected[channel]) begin
                // monitor only pushes item if chan_done intr is asserted
                item_port[channel].write(dut_item);
                `uvm_info(`gfn, $sformatf("\n--> monitor: send dut_item for channel %0d\n%s",
                                          channel, dut_item.sprint()), UVM_MEDIUM)
                bit_cnt = 0;
                cfg.channel_done[channel] = 1'b0;
              end
            end
            // handle reset
            @(posedge reset_asserted);
            // handle errored channels
            error_channel_process(channel, bit_cnt, dut_item);
          join_any
          disable fork;
        end : isolation_thread
      join
    end
  endtask : collect_channel_trans

  virtual task reset_thread();
    forever begin
      @(negedge cfg.vif.rst_ni);
      reset_asserted = 1'b1;
      // implement other clean-up actions under reset here
      cfg.error_injected = '{default:0};
      cfg.length         = '{default:0};
      cfg.channel_done   = '{default:0};
      @(posedge cfg.vif.rst_ni);
      reset_asserted = 1'b0;
    end
  endtask : reset_thread

  virtual task error_channel_process(uint channel, ref uint bit_cnt, ref pattgen_item item);
    @(posedge cfg.error_injected[channel]);
    bit_cnt = 0;
    `uvm_info(`gfn, $sformatf("\n--> monitor: drop dut_item for channel %0d\n%s",
                              channel, item.sprint()), UVM_DEBUG)
    @(negedge cfg.error_injected[channel]);
  endtask: error_channel_process

  // update of_to_end to prevent sim finished when there is any activity on the bus
  // ok_to_end = 0 (bus busy) / 1 (bus idle)
  virtual task monitor_ready_to_end();
    forever begin
      @(cfg.vif.pcl_tx, cfg.vif.pda_tx);
      ok_to_end = (cfg.vif.pcl_tx === {NUM_PATTGEN_CHANNELS{1'b0}}) &&
                  (cfg.vif.pda_tx === {NUM_PATTGEN_CHANNELS{1'b0}});
    end
  endtask : monitor_ready_to_end

  // collect bits aligned by polarized clock
  virtual task get_pattgen_bit(uint channel, output bit bit_o);
    bit stop_thread = 1'b0;

    `DV_CHECK_LT_FATAL(channel, NUM_PATTGEN_CHANNELS, "invalid channel index")
    while (!stop_thread) begin
      fork
        begin : isolation_thread
          fork
            begin
              get_pcl_edge(channel);
              bit_o = cfg.vif.pda_tx[channel];
              stop_thread = 1'b1;
            end
            // if polarity is updated, fork is disabled and the first thread is rerun with
            // updated polarity value to capture data
            @(cfg.polarity[channel]);
          join_any
          disable fork;
        end : isolation_thread
      join
    end
  endtask : get_pattgen_bit

  // Monitor vif.pcl_tx[channel]
  // This task runs with cfg.chk_prediv[channel].
  // if chk_prediv is set, check free running counter 'free_run_cnt'
  // is matched with expected 'div' value to assure
  // pattgen clk div is accurate.
  virtual task mon_pcl(int channel);
    int free_run_cnt, skip_one_cyc;

    wait(cfg.chk_prediv[channel]);
    get_pcl_edge(channel);
    `uvm_info(`gfn, $sformatf("monitor: start mon_pcl channel %0d", channel), UVM_MEDIUM)

    fork
      forever begin
        @(posedge cfg.vif.clk_i);
        free_run_cnt++;
      end
      forever begin
        get_pcl_edge(channel);
        #1;
        `DV_CHECK_EQ(free_run_cnt, cfg.div[channel])
        free_run_cnt = 0;
      end
    join_none
  endtask // mon_pcl

  // Wait edge based on the polarity
  task get_pcl_edge(int channel);
    if (cfg.polarity[channel]) begin
      @(negedge cfg.vif.pcl_tx[channel]);
    end else begin
      @(posedge cfg.vif.pcl_tx[channel]);
    end
  endtask
endclass : pattgen_monitor
