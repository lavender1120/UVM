//---------------------------------------------------------------------- 
//   Copyright 2010 Cadence Design Systems, Inc.
//   All Rights Reserved Worldwide 
// 
//   Licensed under the Apache License, Version 2.0 (the 
//   "License"); you may not use this file except in 
//   compliance with the License.  You may obtain a copy of 
//   the License at 
// 
//       http://www.apache.org/licenses/LICENSE-2.0 
// 
//   Unless required by applicable law or agreed to in 
//   writing, software distributed under the License is 
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
//   CONDITIONS OF ANY KIND, either express or implied.  See 
//   the License for the specific language governing 
//   permissions and limitations under the License. 
//----------------------------------------------------------------------

// This test creates a simple hierarchy where two leaf cells belong
// to two different domains. It verifies that the domains run
// independently in the runtime phases but togehter in the common
// phases.

`define TASK(NAME,DELAY,STARTTIME) \
    task NAME``_phase(uvm_phase phase); \
      phase.raise_objection(this,`"start NAME`"); \
      phase_run[uvm_``NAME``_ph] = 1; \
      `uvm_info(`"NAME`", `"Starting NAME`", UVM_NONE) \
      if($time != STARTTIME)  begin \
        failed = 1; \
        `uvm_error(`"NAME`", $sformatf(`"Expected NAME start time of %0t`",STARTTIME)) \
      end \
      #DELAY; \
      `uvm_info(`"NAME`", `"Ending NAME`", UVM_NONE) \
      phase.drop_objection(this,`"end NAME`"); \
    endtask


module test;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  bit failed = 0;
  bit phase_run[uvm_phase_imp];

  class base extends uvm_component;
    time delay = 300;
    time maxdelay = 5*delay;

    function new(string name, uvm_component parent);
      super.new(name,parent);
    endfunction

    `TASK(reset,delay,0)
    `TASK(main,delay,delay)
    `TASK(shutdown,delay,2*delay)
    `TASK(run,maxdelay,0)

    function void extract_phase(uvm_phase phase);
      phase_run[uvm_extract_ph] = 1;
      `uvm_info("EXTRACT", "Starting Extract", UVM_NONE)
      if($time != maxdelay)  begin
        failed = 1;
        `uvm_error("extract", $sformatf("Expected extract start time of %0t",maxdelay))
      end
      `uvm_info("EXTRACT", "Ending Extract", UVM_NONE)
    endfunction
  endclass

  class leaf extends base;
    function new(string name, uvm_component parent);
      super.new(name,parent);
    endfunction
  endclass

  class env extends base;
    leaf l1, l2; 
    `uvm_component_utils(env)
    function new(string name, uvm_component parent);
      super.new(name,parent);
      l1 = new("l1", this);
      l1.maxdelay = 1500;
      l2 = new("l2", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      l1.set_phase_domain("domain1");
      l2.set_phase_domain("domain2");
    endfunction

  endclass

  class test extends base;
    env env1, env2; 
    `uvm_component_utils(test)
    function new(string name, uvm_component parent);
      super.new(name,parent);
      env1 = new("env1", this);
      env2 = new("env2", this);

      env1.l1.delay = 200;
      env1.l2.delay = 300;

      env2.l1.delay = 100;
      env2.l2.delay = 150;

    endfunction

    function void connect_phase(uvm_phase phase);
      //env1 and env2 comps are in different domains
      env2.l1.set_phase_domain("env_domain1");
      env2.l2.set_phase_domain("env_domain2");
    endfunction

    function void report_phase(uvm_phase phase);
      phase_run[uvm_report_ph] = 1;
      if(phase_run.num() != 6) begin
        failed = 1;
        `uvm_error("NUMPHASES", $sformatf("Expected 6 phases, got %0d", phase_run.num()))
      end
      if(failed) $display("*** UVM TEST FAILED ***");
      else $display("*** UVM TEST PASSED ***");
    endfunction
  endclass
  initial run_test();
endmodule