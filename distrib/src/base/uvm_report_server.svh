//
//------------------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc. 
//   Copyright 2010 Synopsys, Inc.
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
//------------------------------------------------------------------------------

`ifndef UVM_REPORT_SERVER_SVH
`define UVM_REPORT_SERVER_SVH

typedef class uvm_report_object;

//------------------------------------------------------------------------------
//
// CLASS: uvm_report_server
//
// uvm_report_server is a global server that processes all of the reports
// generated by an uvm_report_handler. None of its methods are intended to be
// called by normal testbench code, although in some circumstances the virtual
// methods process_report and/or compose_uvm_info may be overloaded in a
// subclass.
//
//------------------------------------------------------------------------------

typedef class uvm_default_report_server;
virtual class uvm_report_server extends uvm_object;
        function string get_type_name();
                return "uvm_report_server";
        endfunction
        function new(string name="base");
                super.new(name);
        endfunction

        // Function: set_max_quit_count
        // ~count~ is the maximum number of ~UVM_QUIT~ actions the uvm_report_server
        // will tolerate before before invoking client.die().
        // when ~overridable~=0 is passed the set quit count cannot be changed again
        pure virtual  function void set_max_quit_count(int count, bit overridable = 1);

        // Function: get_max_quit_count
        // returns the currently configured max quit count
        pure virtual  function int get_max_quit_count();

        // Function: set_quit_count
        // sets the current number of ~UVM_QUIT~ actions already passed through this uvm_report_server
        pure virtual  function void set_quit_count(int quit_count);

        // Function: get_quit_count
        // returns the current number of ~UVM_QUIT~ actions already passed through this server
        pure virtual  function int get_quit_count();

        // Function: set_severity_count
        // sets the count of already passed messages with severity ~severity~ to ~count~
        pure virtual  function void set_severity_count(uvm_severity severity, int count);
        // Function: get_severity_count
        // returns the count of already passed messages with severity ~severity~
        pure virtual  function int get_severity_count(uvm_severity severity);

        // Function: set_id_count
        // sets the count of already passed messages with ~id~ to ~count~
        pure virtual  function void set_id_count(string id, int count);

        // Function: get_id_count
        // returns the count of already passed messages with ~id~
        pure virtual  function int get_id_count(string id);


        // Function: get_id_set
        // returns the set of id's already used by this uvm_report_server
        pure virtual function void get_id_set(output string q[$]);

        // Function: get_severity_set
        // returns the set of severities's already used by this uvm_report_server
        pure virtual function void get_severity_set(output uvm_severity q[$]);

        // Function: set_message_database
        // sets the <uvm_tr_database> used for recording messages
        pure virtual function void set_message_database(uvm_tr_database database);

        // Function: get_message_database
        // returns the <uvm_tr_database> used for recording messages
        pure virtual function uvm_tr_database get_message_database();

        // Function: do_copy
        // copies all message statistic severity,id counts to the dest uvm_report_server
        // the copy is cummulative (only items from the source are transfered, already existing entries are not deleted,
        // existing entries/counts are overridden when they exist in the source set)
        function void do_copy (uvm_object rhs);
                uvm_report_server rhs_;

                super.do_copy(rhs);
                assert($cast(rhs_,rhs)) else `uvm_error("UVM/REPORT/SERVER/RPTCOPY","cannot copy to report_server from the given datatype")

                begin
                        uvm_severity q[$];
                        rhs_.get_severity_set(q);
                        foreach(q[s])
                                set_severity_count(q[s],rhs_.get_severity_count(q[s]));
                end

                begin
                        string q[$];
                        rhs_.get_id_set(q);
                        foreach(q[s])
                                set_id_count(q[s],rhs_.get_id_count(q[s]));
                end

                set_message_database(rhs_.get_message_database());
                set_max_quit_count(rhs_.get_max_quit_count());
                set_quit_count(rhs_.get_quit_count());
        endfunction


        // Function- process_report_message
        //
        // Main entry for uvm_report_server, combines execute_report_message and compose_report_message

        pure virtual function void process_report_message(uvm_report_message report_message);


        // Function: execute_report_message
        //
        // Processes the provided message per the actions contained within.
        //
        // Expert users can overload this method to customize action processing.

        pure virtual function void execute_report_message(uvm_report_message report_message,
                                                          string composed_message);


        // Function: compose_report_message
        //
        // Constructs the actual string sent to the file or command line
        // from the severity, component name, report id, and the message itself.
        //
        // Expert users can overload this method to customize report formatting.

        pure virtual function string compose_report_message(uvm_report_message report_message,
                                                            string report_object_name = "");


        // Function: report_summarize
        //
        // Outputs statistical information on the reports issued by this central report
        // server. This information will be sent to the command line if ~file~ is 0, or
        // to the file descriptor ~file~ if it is not 0.
        //
        // The run_test method in uvm_top calls this method.

        pure virtual function void report_summarize(UVM_FILE file=0);


`ifndef UVM_NO_DEPRECATED 

        // Function- summarize
        //

        virtual function void summarize(UVM_FILE file=0);
          report_summarize(file);
        endfunction

`endif

        // Function: set_server
        //
        // Sets the global report server to use for reporting. The report
        // server is responsible for formatting messages.
        // in addition to setting the server this also copies the severity/id counts
        // from the current report_server to the new one

        static function void set_server(uvm_report_server server);
                server.copy(uvm_coreservice.get_report_server());
                uvm_coreservice.set_report_server(server);
        endfunction


        // Function: get_server
        //
        // Gets the global report server. The method will always return
        // a valid handle to a report server.

        static function uvm_report_server get_server();
                return uvm_coreservice.get_report_server();
        endfunction
endclass

class uvm_default_report_server extends uvm_report_server;

  local int m_quit_count;
  local int m_max_quit_count; 
  bit max_quit_overridable = 1;
  local int m_severity_count[uvm_severity];
  protected int m_id_count[string];
   protected uvm_tr_database m_message_db;
   protected uvm_tr_stream m_streams[string][string]; // ro.name,rh.name
   

  // Variable: enable_report_id_count_summary
  //
  // A flag to enable report count summary for each ID
  //
  bit enable_report_id_count_summary=1;


  // Variable: record_all_messages
  //
  // A flag to force recording of all messages (add UVM_RM_RECORD action)
  //
  bit record_all_messages = 0;

  
  // Variable: show_verbosity
  //
  // A flag to include verbosity in the messages, e.g.
  // 
  // "UVM_INFO(UVM_MEDIUM) file.v(3) @ 60: reporter [ID0] Message 0"
  //
  bit show_verbosity = 0;


  // Variable: show_terminator
  //
  // A flag to add a terminator in the messages, e.g.
  // 
  // "UVM_INFO file.v(3) @ 60: reporter [ID0] Message 0 -UVM_INFO"
  //
  bit show_terminator = 0;

  // Needed for callbacks
  function string get_type_name();
    return "uvm_default_report_server";
  endfunction


  // Function: new
  //
  // Creates an instance of the class.

  function new(string name = "uvm_report_server");
    super.new(name);
    set_max_quit_count(0);
    reset_quit_count();
    reset_severity_counts();
  endfunction


  // Function: print
  //
  // The uvm_report_server implements the uvm_object::do_print() such that
  // uvm_server_handler::print() method provides UVM printer formatted output
  // of the current configuration.  A snippet of example output is shown here:
  //
  // |uvm_report_server                 uvm_report_server  -     @13  
  // |  quit_count                      int                32    'd0  
  // |  max_quit_count                  int                32    'd5  
  // |  max_quit_overridable            bit                1     'b1  
  // |  severity_count                  severity counts    4     -    
  // |    [UVM_INFO]                    integral           32    'd4  
  // |    [UVM_WARNING]                 integral           32    'd2  
  // |    [UVM_ERROR]                   integral           32    'd50 
  // |    [UVM_FATAL]                   integral           32    'd10 
  // |  id_count                        id counts          4     -    
  // |    [ID1]                         integral           32    'd1  
  // |    [ID2]                         integral           32    'd2  
  // |    [RNTST]                       integral           32    'd1  
  // |  enable_report_id_count_summary  bit                1     'b1  
  // |  record_all_messages             bit                1     `b0
  // |  show_verbosity                  bit                1     `b0
  // |  show_terminator                 bit                1     `b0


  // Print to show report server state
  virtual function void do_print (uvm_printer printer);

    uvm_severity l_severity_count_index;
    string l_id_count_index;

    printer.print_int("quit_count", m_quit_count, $bits(m_quit_count), UVM_DEC,
      ".", "int");
    printer.print_int("max_quit_count", m_max_quit_count,
      $bits(m_max_quit_count), UVM_DEC, ".", "int");
    printer.print_int("max_quit_overridable", max_quit_overridable,
      $bits(max_quit_overridable), UVM_BIN, ".", "bit");

    if (m_severity_count.first(l_severity_count_index)) begin
      printer.print_array_header("severity_count",m_severity_count.size(),"severity counts");
      do
        printer.print_int($sformatf("[%s]",l_severity_count_index.name()),
          m_severity_count[l_severity_count_index], 32, UVM_DEC);
      while (m_severity_count.next(l_severity_count_index));
      printer.print_array_footer();
    end

    if (m_id_count.first(l_id_count_index)) begin
      printer.print_array_header("id_count",m_id_count.size(),"id counts");
      do
        printer.print_int($sformatf("[%s]",l_id_count_index),
          m_id_count[l_id_count_index], 32, UVM_DEC);
      while (m_id_count.next(l_id_count_index));
      printer.print_array_footer();
    end

    printer.print_int("enable_report_id_count_summary", enable_report_id_count_summary,
      $bits(enable_report_id_count_summary), UVM_BIN, ".", "bit");
    printer.print_int("record_all_messages", record_all_messages,
      $bits(record_all_messages), UVM_BIN, ".", "bit");
    printer.print_int("show_verbosity", show_verbosity,
      $bits(show_verbosity), UVM_BIN, ".", "bit");
    printer.print_int("show_terminator", show_terminator,
      $bits(show_terminator), UVM_BIN, ".", "bit");

  endfunction


  //----------------------------------------------------------------------------
  // Group: Quit Count
  //----------------------------------------------------------------------------


  // Function: get_max_quit_count

  function int get_max_quit_count();
    return m_max_quit_count;
  endfunction

  // Function: set_max_quit_count
  //
  // Get or set the maximum number of COUNT actions that can be tolerated
  // before an UVM_EXIT action is taken. The default is 0, which specifies
  // no maximum.

  function void set_max_quit_count(int count, bit overridable = 1);
    if (max_quit_overridable == 0) begin
      uvm_report_info("NOMAXQUITOVR", 
        $sformatf("The max quit count setting of %0d is not overridable to %0d due to a previous setting.", 
        m_max_quit_count, count), UVM_NONE);
      return;
    end
    max_quit_overridable = overridable;
    m_max_quit_count = count < 0 ? 0 : count;
  endfunction


  // Function: get_quit_count

  function int get_quit_count();
    return m_quit_count;
  endfunction

  // Function: set_quit_count

  function void set_quit_count(int quit_count);
    m_quit_count = quit_count < 0 ? 0 : quit_count;
  endfunction

  // Function: incr_quit_count

  function void incr_quit_count();
    m_quit_count++;
  endfunction

  // Function: reset_quit_count
  //
  // Set, get, increment, or reset to 0 the quit count, i.e., the number of
  // COUNT actions issued.

  function void reset_quit_count();
    m_quit_count = 0;
  endfunction

  // Function: is_quit_count_reached
  //
  // If is_quit_count_reached returns 1, then the quit counter has reached
  // the maximum.

  function bit is_quit_count_reached();
    return (m_quit_count >= m_max_quit_count);
  endfunction


  //----------------------------------------------------------------------------
  // Group: Severity Count
  //----------------------------------------------------------------------------
 

  // Function: get_severity_count

  function int get_severity_count(uvm_severity severity);
    return m_severity_count[severity];
  endfunction

  // Function: set_severity_count

  function void set_severity_count(uvm_severity severity, int count);
    m_severity_count[severity] = count < 0 ? 0 : count;
  endfunction

  // Function: incr_severity_count

  function void incr_severity_count(uvm_severity severity);
    m_severity_count[severity]++;
  endfunction

  // Function: reset_severity_counts
  //
  // Set, get, or increment the counter for the given severity, or reset
  // all severity counters to 0.

  function void reset_severity_counts();
    uvm_severity s;
    s = s.first();
    forever begin
      m_severity_count[s] = 0;
      if(s == s.last()) break;
      s = s.next();
    end
  endfunction


  //----------------------------------------------------------------------------
  // Group: id Count
  //----------------------------------------------------------------------------


  // Function: get_id_count

  function int get_id_count(string id);
    if(m_id_count.exists(id))
      return m_id_count[id];
    return 0;
  endfunction

  // Function: set_id_count

  function void set_id_count(string id, int count);
    m_id_count[id] = count < 0 ? 0 : count;
  endfunction

  // Function: incr_id_count
  //
  // Set, get, or increment the counter for reports with the given id.

  function void incr_id_count(string id);
    if(m_id_count.exists(id))
      m_id_count[id]++;
    else
      m_id_count[id] = 1;
  endfunction

  //----------------------------------------------------------------------------
  // Group: message recording
  //
  // The ~uvm_default_report_server~ will record messages into the message
  // database, using one transaction per message, and one stream per report
  // object/handler pair.
  //
  //----------------------------------------------------------------------------

   // Function: set_message_database
   // sets the <uvm_tr_database> used for recording messages
   virtual function void set_message_database(uvm_tr_database database);
      m_message_db = database;
   endfunction : set_message_database

   // Function: get_message_database
   // returns the <uvm_tr_database> used for recording messages
   //
   virtual function uvm_tr_database get_message_database();
      return m_message_db;
   endfunction : get_message_database


  virtual function void get_severity_set(output uvm_severity q[$]);
    foreach(m_severity_count[idx])
      q.push_back(idx);
  endfunction


  virtual function void get_id_set(output string q[$]);
    foreach(m_id_count[idx])
      q.push_back(idx);
  endfunction


  // Function- f_display
  //
  // This method sends string severity to the command line if file is 0 and to
  // the file(s) specified by file if it is not 0.

  function void f_display(UVM_FILE file, string str);
    if (file == 0)
      $display("%s", str);
    else
      $fdisplay(file, "%s", str);
  endfunction


  // Function- process_report_message
  //
  //

  virtual function void process_report_message(uvm_report_message report_message);

    uvm_report_handler l_report_handler = report_message.get_report_handler();
    	process p = process::self();
    bit report_ok = 1;

    // Set the report server for this message
    report_message.set_report_server(this);

`ifndef UVM_NO_DEPRECATED 

    // The hooks can do additional filtering.  If the hook function
    // return 1 then continue processing the report.  If the hook
    // returns 0 then skip processing the report.

    if(report_message.get_action() & UVM_CALL_HOOK)
      report_ok = l_report_handler.run_hooks(
        report_message.get_report_object(),
        report_message.get_severity(), 
        report_message.get_id(), 
        report_message.get_message(), 
        report_message.get_verbosity(), 
        report_message.get_filename(), 
        report_message.get_line());

`endif

    if(report_ok)
      report_ok = uvm_report_catcher::process_all_report_catchers(report_message);

    if(uvm_action_type'(report_message.get_action()) == UVM_NO_ACTION)
      report_ok = 0;

    if(report_ok) begin	
      string m;

      // give the global server a chance to intercept the calls
      uvm_report_server svr = uvm_coreservice.get_report_server();

`ifdef UVM_DEPRECATED_REPORTING

      // no need to compose when neither UVM_DISPLAY nor UVM_LOG is set
      if (report_message.get_action() & (UVM_LOG|UVM_DISPLAY))
        m = compose_message(report_message.get_severity(), 
                              l_report_handler.get_full_name(), 
			      report_message.get_id(),
			      report_message.get_message(), 
                              report_message.get_filename(),
			      report_message.get_line()); 

      process_report(report_message.get_severity(), 
			 l_report_handler.get_full_name(),
			 report_message.get_id(),
		         report_message.get_message(), 
			 report_message.get_action(),
                         report_message.get_file(),
			 report_message.get_filename(),
		         report_message.get_line(),
			 m, 
			 report_message.get_verbosity(),
			 report_message.get_report_object());

`else

      // no need to compose when neither UVM_DISPLAY nor UVM_LOG is set
      if (report_message.get_action() & (UVM_LOG|UVM_DISPLAY))
        m = svr.compose_report_message(report_message);

      svr.execute_report_message(report_message, m);

`endif
    end

  endfunction


  //----------------------------------------------------------------------------
  // Group: Message Processing
  //----------------------------------------------------------------------------


  // Function: execute_report_message
  //
  // Processes the provided message per the actions contained within.
  //
  // Expert users can overload this method to customize action processing.
 
  virtual function void execute_report_message(uvm_report_message report_message,
                                               string composed_message);
                                               
                                               process p = process::self();
                                               
    // Update counts 
    incr_severity_count(report_message.get_severity());
    incr_id_count(report_message.get_id());

    if (record_all_messages)
      report_message.set_action(report_message.get_action() | UVM_RM_RECORD);

    // UVM_RM_RECORD action
    if(report_message.get_action() & UVM_RM_RECORD) begin
       uvm_tr_stream stream;
       uvm_report_object ro = report_message.get_report_object();
       uvm_report_handler rh = report_message.get_report_handler();

       // Check for pre-existing stream
       if (m_streams.exists(ro.get_name()) && (m_streams[ro.get_name()].exists(rh.get_name())))
         stream = m_streams[ro.get_name()][rh.get_name()];

       // If no pre-existing stream (or for some reason pre-existing stream was null)
       if (stream == null) begin
          uvm_tr_database db;

          // Grab the database
          db = get_message_database();

          // If database is null, use the default database
          if (db == null) begin
             uvm_coreservice_t cs = uvm_coreservice_t::get();
             db = cs.get_default_tr_database();
          end
          if (db != null) begin
             // Open the stream.  Name=report object name, scope=report handler name, type=MESSAGES
             stream = db.open_stream(ro.get_name(), rh.get_name(), "MESSAGES");
             // Save off the openned stream
             m_streams[ro.get_name()][rh.get_name()] = stream;
          end
       end
       if (stream != null) begin
          uvm_recorder recorder = stream.open_recorder(report_message.get_name(),,report_message.get_type_name());
             if (recorder != null) begin
             report_message.record(recorder);
             recorder.free();
          end
       end
    end

    // DISPLAY action
    if(report_message.get_action() & UVM_DISPLAY)
      $display("%s", composed_message);

    // LOG action
    // if log is set we need to send to the file but not resend to the
    // display. So, we need to mask off stdout for an mcd or we need
    // to ignore the stdout file handle for a file handle.
    if(report_message.get_action() & UVM_LOG)
      if( (report_message.get_file() == 0) || 
        (report_message.get_file() != 32'h8000_0001) ) begin //ignore stdout handle
        UVM_FILE tmp_file = report_message.get_file();
        if((report_message.get_file() & 32'h8000_0000) == 0) begin //is an mcd so mask off stdout
          tmp_file = report_message.get_file() & 32'hffff_fffe;
        end
      f_display(tmp_file, composed_message);
    end    

    // Process the UVM_COUNT action
    if(report_message.get_action() & UVM_COUNT) begin
      if(get_max_quit_count() != 0) begin
        incr_quit_count();
        // If quit count is reached, add the UVM_EXIT action.
        if(is_quit_count_reached()) begin
          report_message.set_action(report_message.get_action() | UVM_EXIT);
        end
      end  
    end

    // Process the UVM_EXIT action
    if(report_message.get_action() & UVM_EXIT) begin
      uvm_root l_root = uvm_coreservice.get_root();
      l_root.die();
    end

    // Process the UVM_STOP action
    if (report_message.get_action() & UVM_STOP) 
      $stop;

  endfunction


  // Function: compose_report_message
  //
  // Constructs the actual string sent to the file or command line
  // from the severity, component name, report id, and the message itself. 
  //
  // Expert users can overload this method to customize report formatting.

  virtual function string compose_report_message(uvm_report_message report_message,
                                                 string report_object_name = "");

    string sev_string;
    uvm_severity l_severity;
    uvm_verbosity l_verbosity;
    string filename_line_string;
    string time_str;
    string line_str;
    string context_str;
    string verbosity_str;
    string terminator_str;
    string msg_body_str;
    uvm_report_message_element_container el_container;
    string prefix;
    uvm_report_handler l_report_handler;

    l_severity = report_message.get_severity();
    sev_string = l_severity.name();

    if (report_message.get_filename() != "") begin
      line_str.itoa(report_message.get_line());
      filename_line_string = {report_message.get_filename(), "(", line_str, ") "};
    end

    // Make definable in terms of units.
    $swrite(time_str, "%0t", $time);
 
    if (report_message.get_context() != "")
      context_str = {"@@", report_message.get_context()};

    if (show_verbosity) begin
      if ($cast(l_verbosity, report_message.get_verbosity()))
        verbosity_str = l_verbosity.name();
      else
        verbosity_str.itoa(report_message.get_verbosity());
      verbosity_str = {"(", verbosity_str, ")"};
    end

    if (show_terminator)
      terminator_str = {" -",sev_string};

    el_container = report_message.get_element_container();
    if (el_container.size() == 0)
      msg_body_str = report_message.get_message();
    else begin
      prefix = uvm_default_printer.knobs.prefix;
      uvm_default_printer.knobs.prefix = " +";
      msg_body_str = {report_message.get_message(), "\n", el_container.sprint()};
      uvm_default_printer.knobs.prefix = prefix;
    end

    if (report_object_name == "") begin
      l_report_handler = report_message.get_report_handler();
      report_object_name = l_report_handler.get_full_name();
    end

    compose_report_message = {sev_string, verbosity_str, " ", filename_line_string, "@ ", 
      time_str, ": ", report_object_name, context_str,
      " [", report_message.get_id(), "] ", msg_body_str, terminator_str};

  endfunction 


  // Function: report_summarize
  //
  // Outputs statistical information on the reports issued by this central report
  // server. This information will be sent to the command line if ~file~ is 0, or
  // to the file descriptor ~file~ if it is not 0.
  //
  // The run_test method in uvm_top calls this method.

  virtual function void report_summarize(UVM_FILE file=0);
    string id;
    string name;
    string output_str;
    string q[$];

    uvm_report_catcher::summarize();
    q.push_back("\n--- UVM Report Summary ---\n\n");

    if(m_max_quit_count != 0) begin
      if ( m_quit_count >= m_max_quit_count )
        q.push_back("Quit count reached!\n");
      q.push_back($sformatf("Quit count : %5d of %5d\n",m_quit_count, m_max_quit_count));
    end

    q.push_back("** Report counts by severity\n");
    foreach(m_severity_count[s]) begin
      q.push_back($sformatf("%s :%5d\n", s.name(), m_severity_count[s]));
    end

    if (enable_report_id_count_summary) begin
      q.push_back("** Report counts by id\n");
      foreach(m_id_count[id])
        q.push_back($sformatf("[%s] %5d\n", id, m_id_count[id]));
    end

    `uvm_info("UVM/REPORT/SERVER",`UVM_STRING_QUEUE_STREAMING_PACK(q),UVM_LOW)
  endfunction


`ifndef UVM_NO_DEPRECATED

  // Function- process_report
  //
  // Calls <compose_message> to construct the actual message to be
  // output. It then takes the appropriate action according to the value of
  // action and file. 
  //
  // This method can be overloaded by expert users to customize the way the
  // reporting system processes reports and the actions enabled for them.

  virtual function void process_report(
      uvm_severity severity,
      string name,
      string id,
      string message,
      uvm_action action,
      UVM_FILE file,
      string filename,
      int line,
      string composed_message,
      int verbosity_level,
      uvm_report_object client
      );
    uvm_report_message l_report_message;

    l_report_message = uvm_report_message::new_report_message();
    l_report_message.set_report_message(severity, id, message, 
					verbosity_level, filename, line, "");
    l_report_message.set_report_object(client);
    l_report_message.set_report_handler(client.get_report_handler());
    l_report_message.set_file(file);
    l_report_message.set_action(action);
    l_report_message.set_report_server(this);

    execute_report_message(l_report_message, composed_message);
  endfunction

  
  // Function- compose_message
  //
  // Constructs the actual string sent to the file or command line
  // from the severity, component name, report id, and the message itself. 
  //
  // Expert users can overload this method to customize report formatting.

  virtual function string compose_message(
      uvm_severity severity,
      string name,
      string id,
      string message,
      string filename,
      int    line
      );
    uvm_report_message l_report_message;

    l_report_message = uvm_report_message::new_report_message();
    l_report_message.set_report_message(severity, id, message, 
					UVM_NONE, filename, line, "");

    return compose_report_message(l_report_message, name);
  endfunction 


`endif


endclass


`endif // UVM_REPORT_SERVER_SVH
