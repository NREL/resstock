begin
  require 'ffi'
rescue LoadError
  fail "Could not load ffi."
end

module SscApi

  class SscFfi
  
    extend FFI::Library
    
    ssc_path = nil
    if /win/.match(RUBY_PLATFORM) or /mingw/.match(RUBY_PLATFORM)
      if RUBY_PLATFORM.include? "x64"
        ssc_path = "#{File.dirname(__FILE__)}/sam-sdk-2017-1-17-r1/win64/ssc.dll"
      else
        ssc_path = "#{File.dirname(__FILE__)}/sam-sdk-2017-1-17-r1/win32/ssc.dll"
      end
    elsif /darwin/.match(RUBY_PLATFORM)
      ssc_path = "#{File.dirname(__FILE__)}/sam-sdk-2017-1-17-r1/osx64/ssc.dylib"
    elsif /linux/.match(RUBY_PLATFORM)
      ssc_path = "#{File.dirname(__FILE__)}/sam-sdk-2017-1-17-r1/linux64/ssc.so"
    end
    
    if ssc_path.nil?
      fail "Platform not supported: #{RUBY_PLATFORM}"
    elsif !File.exist? ssc_path
      fail "File not found: #{ssc_path}"
    end
    ffi_lib ssc_path

    SSC_INVALID ||= 0
    SSC_STRING ||= 1
    SSC_NUMBER ||= 2
    SSC_ARRAY ||= 3
    SSC_MATRIX ||= 4
    SSC_TABLE ||= 5

    SSC_INPUT ||= 1
    SSC_OUTPUT ||= 2
    SSC_INOUT ||= 3

    SSC_LOG ||= 0
    SSC_UPDATE ||= 1
    SSC_EXECUTE ||= 2

    SSC_NOTICE ||= 1
    SSC_WARNING ||= 2
    SSC_ERROR ||= 3

    SSC_FALSE ||= 0
    SSC_TRUE ||= 1

    attach_function :ssc_version, [  ], :int
    attach_function :ssc_build_info, [  ], :string
    attach_function :ssc_data_create, [  ], :pointer
    attach_function :ssc_data_free, [ :pointer ], :void
    attach_function :ssc_data_clear, [ :pointer ], :void
    attach_function :ssc_data_unassign, [ :pointer, :string ], :void
    attach_function :ssc_data_query, [ :pointer, :string ], :int
    attach_function :ssc_data_first, [ :pointer ], :string
    attach_function :ssc_data_next, [ :pointer ], :string
    attach_function :ssc_data_set_string, [ :pointer, :string, :string ], :void
    attach_function :ssc_data_set_number, [ :pointer, :string, :float ], :void
    attach_function :ssc_data_set_array, [ :pointer, :string, :pointer, :int ], :void
    attach_function :ssc_data_set_matrix, [ :pointer, :string, :pointer, :int, :int ], :void
    attach_function :ssc_data_set_table, [ :pointer, :string, :pointer ], :void
    attach_function :ssc_data_get_string, [ :pointer, :string ], :string
    attach_function :ssc_data_get_number, [ :pointer, :string, :pointer ], :int
    attach_function :ssc_data_get_array, [ :pointer, :string, :pointer ], :pointer
    attach_function :ssc_data_get_matrix, [ :pointer, :string, :pointer, :pointer ], :pointer
    attach_function :ssc_data_get_table, [ :pointer, :string ], :pointer
    attach_function :ssc_module_entry, [ :int ], :pointer
    attach_function :ssc_entry_name, [ :pointer ], :string
    attach_function :ssc_entry_description, [ :pointer ], :string
    attach_function :ssc_entry_version, [ :pointer ], :int
    attach_function :ssc_module_create, [ :string ], :pointer
    attach_function :ssc_module_free, [ :pointer ], :void
    attach_function :ssc_module_var_info, [ :pointer, :int ], :pointer
    attach_function :ssc_info_var_type, [ :pointer ], :int
    attach_function :ssc_info_data_type, [ :pointer ], :int
    attach_function :ssc_info_name, [ :pointer ], :string
    attach_function :ssc_info_label, [ :pointer ], :string
    attach_function :ssc_info_units, [ :pointer ], :string
    attach_function :ssc_info_meta, [ :pointer ], :string
    attach_function :ssc_info_group, [ :pointer ], :string
    attach_function :ssc_info_required, [ :pointer ], :string
    attach_function :ssc_info_constraints, [ :pointer ], :string
    attach_function :ssc_info_uihint, [ :pointer ], :string
    attach_function :ssc_module_exec_set_print, [ :int ], :void
    attach_function :ssc_module_exec_simple, [ :string, :pointer ], :int
    attach_function :ssc_module_exec_simple_nothread, [ :string, :pointer ], :string
    attach_function :ssc_module_exec, [ :pointer, :pointer ], :int
    attach_function :ssc_module_exec_with_handler, [ :pointer, :pointer, callback([ :pointer, :pointer, :int, :float, :float, :string, :string, :pointer ], :pointer), :pointer ], :int
    attach_function :ssc_module_log, [ :pointer, :int, :pointer, :pointer ], :string
    attach_function :__ssc_segfault, [  ], :void
    
  end
  
end
    