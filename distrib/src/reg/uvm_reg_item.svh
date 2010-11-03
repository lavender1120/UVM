//
//--------------------------------------------------------------
//    Copyright 2004-2009 Synopsys, Inc.
//    Copyright 2010 Mentor Graphics Corp.
//    All Rights Reserved Worldwide
//
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
//--------------------------------------------------------------
//
 
//------------------------------------------------------------------------------
// CLASS: uvm_reg_item
//
// Defines an abstract register transaction item. No bus-specific information
// is present, although a handle a <uvm_reg_map> is provided in case the user
// wishes to implement a custom address translation algorithm.
//------------------------------------------------------------------------------

class uvm_reg_item extends uvm_sequence_item;

  `uvm_object_utils(uvm_reg_item)

  // Variable: element_kind
  //
  // Kind of element being accessed: REG, MEM, or FIELD. See <uvm_elem_kind_e>.
  //
  uvm_elem_kind_e element_kind;


  // Variable: element
  //
  // A handle to the RegModel model element associated with this transaction.
  // Use <element_kind> to determine the type to cast  to: <uvm_reg>,
  // <uvm_mem>, or <uvm_reg_field>.
  //
  uvm_object element;


  // Variable: kind
  //
  // Kind of access: READ or WRITE.
  //
  rand uvm_access_e kind;


  // Variable: value
  //
  // The value to write to, or after completion, the value read from the DUT.
  // Burst operations use the <values> property.
  //
  rand uvm_reg_data_t value[];


  // TODO: parameterize
  constraint max_values { value.size() > 0 && value.size() < 1000; }

  // Variable: offset
  //
  // For memory accesses, the offset address. For bursts,
  // the ~starting~ offset address.
  //
  rand uvm_reg_addr_t offset;


  // Variable: status
  //
  // The result of the transaction: IS_OK, HAS_X, or ERROR.
  // See <uvm_status_e>.
  //
  uvm_status_e status;


  // Variable: local_map
  //
  // The local map used to obtain addresses. Users may customize 
  // address-translation using this map. Access to the sequencer
  // and bus adapter can be obtained by getting this map's root map,
  // then calling <uvm_reg_map::get_sequencer> and 
  // <uvm_reg_map::get_adapter>.
  //
  uvm_reg_map local_map;


  // Variable: map
  //
  // The original map specified for the operation. The actual <map>
  // used may differ when a test or sequence written at the block
  // level is reused at the system level.
  //
  uvm_reg_map map;


  // Variable: path
  //
  // The path being used: BFM or BACKDOOR. Currently, uvm_reg_item transactions
  // are used only during frontdoor (BFM) accesses.
  //
  uvm_path_e path;


  // Variable: parent
  //
  // The sequence from which the operation originated.
  //
  rand uvm_sequence_base parent;


  // Variable: prior
  //
  // The priority requested of this transfer, as defined by
  // <uvm_sequence_base::start_item>.
  //
  int prior = -1;


  // Variable: extension
  //
  // Handle to optional user data, as conveyed in the call to write, read,
  // mirror, or update call. Must derive from uvm_object. 
  //
  rand uvm_object extension;


  // Variable: bd_kind
  //
  // If path is UVM_BACKDOOR, this member specifies the abstraction 
  // kind for the backdoor access, e.g. "RTL" or "GATES".
  //
  string bd_kind = "";


  // Variable: fname
  //
  // The file name from where this transaction originated, if provided
  // at the call site.
  //
  string fname = "";


  // Variable: lineno
  //
  // The file name from where this transaction originated, if provided 
  // at the call site.
  //
  int lineno = 0;


  // Function: new
  //
  // Create a new instance of this type, giving it the optional ~name~.
  //
  function new(string name="");
    super.new(name);
    value = new[1];
  endfunction


  // Function: convert2string
  //
  // Returns a string showing the contents of this transaction.
  //
  virtual function string convert2string();
    string s,value_s;
    s = {"kind=",kind.name(),
         " ele_kind=",element_kind.name(),
         " ele_name=",element==null?"null":element.get_full_name() };

    if (value.size() > 1 && uvm_report_enabled(UVM_HIGH)) begin
      value_s = "'{";
      foreach (value[i])
         value_s = {value_s,$sformatf("%0h,",value[i])};
      value_s[value_s.len()-1]="}";
    end
    else
      value_s = $sformatf("%0h",value[0]);
    s = {s, " value=",value_s};

    if (element_kind == UVM_MEM)
      s = {s, $sformatf(" offset=%0h",offset)};
    s = {s," map=",(map==null?"null":map.get_full_name())," path=",path.name()};
    s = {s," status=",status.name()};
    return s;
  endfunction


  // Function: do_copy
  //
  // Copy the ~rhs~ object into this object. The ~rhs~ object must
  // derive from <uvm_reg_item>.
  //
  virtual function void do_copy(uvm_object rhs);
    uvm_reg_item rhs_;
    assert(rhs != null);
    if (!$cast(rhs_,rhs)) begin
      `uvm_error("WRONG_TYPE","Provided rhs is not of type uvm_reg_item")
      return;
    end
    super.copy(rhs);
    element_kind = rhs_.element_kind;
    element = rhs_.element;
    kind = rhs_.kind;
    value = rhs_.value;
    offset = rhs_.offset;
    status = rhs_.status;
    local_map = rhs_.local_map;
    map = rhs_.map;
    path = rhs_.path;
    extension = rhs_.extension;
    bd_kind = rhs_.bd_kind;
    parent = rhs_.parent;
    prior = rhs_.prior;
    fname = rhs_.fname;
    lineno = rhs_.lineno;
  endfunction

endclass



//------------------------------------------------------------------------------
//
// TITLE: uvm_reg_bus_op
//
// Defines a generic bus transaction for register and memory accesses, having
// ~kind~ (read or write), ~address~, ~data~, and ~byte enable~ information.
// If the bus is narrower than the register or memory location being accessed,
// there will be multiple of these bus operations for every abstract
// <uvm_reg_item> transaction. In this case, ~data~ represents the portion 
// of <uvm_reg_item::value> being transferred during this bus cycle. 
// If the bus is wide enough to perform the register or memory operation in
// a single cycle, ~data~ will be the same as <uvm_reg_item::value>.
//------------------------------------------------------------------------------

typedef struct {

  // Variable: info
  //
  // The bus-independent read/write information. See <uvm_reg_item>.

  //uvm_reg_item info;

  // Variable: kind
  //
  // Kind of access: READ or WRITE.
  //
  uvm_access_e kind;


  // Variable: addr
  //
  // The bus address.
  //
  uvm_reg_addr_t addr;


  // Variable: data
  //
  // The data to write. If the bus width is smaller than the register or
  // memory width, ~data~ represents only the portion of ~value~ that is
  // being transferred this bus cycle.
  //
  uvm_reg_data_t data;

   
  // Variable: n_bits
  //
  // The number of bits of <uvm_reg_item::value> being transferred by
  // this transaction.

  int n_bits;

  /*
  constraint valid_n_bits {
     n_bits > 0;
     n_bits <= `UVM_REG_DATA_WIDTH;
  }
  */


  // Variable: byte_en
  //
  // Enables for the byte lanes on the bus. Meaningful only when the
  // bus supports byte enables and the operation originates from a field
  // write/read.
  //
  uvm_reg_byte_en_t byte_en;


  // Variable: status
  //
  // The result of the transaction: UVM_IS_OK, UVM_HAS_X, UVM_NOT_OK.
  // See <uvm_status_e>.
  //
  uvm_status_e status;

} uvm_reg_bus_op;


