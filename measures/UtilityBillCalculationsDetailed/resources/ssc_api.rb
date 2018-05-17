
require "#{File.dirname(__FILE__)}/ssc_ffi"
require 'matrix'

module SscApi

  SSC_INVALID = 0
  SSC_STRING = 1
  SSC_NUMBER = 2
  SSC_ARRAY = 3
  SSC_MATRIX = 4

  SSC_INPUT = 1
  SSC_OUTPUT = 2
  SSC_INOUT = 3

  SSC_LOG = 0
  SSC_UPDATE = 1
  SSC_EXECUTE = 2

  SSC_NOTICE = 1
  SSC_WARNING = 2
  SSC_ERROR = 3

  class << self

    # Returns version and build information for the SSC API library.
    #
    # @return [Hash] containing version and build info
    def api_info
      info = {}

      info["version"] = SscFfi.ssc_version
      info["build_info"] = SscFfi.ssc_build_info

      info
    end

    # Returns info on the computational modules available in the SSC API library.
    #
    # @return [Hash] containing information on computational modules available
    def module_list
      modules = []

      done = false
      i = 0
      until done
        the_module = module_info_by_index(i)
        the_module.nil? ? done = true : modules << the_module
        i += 1
      end

      modules
    end

    # Returns info on a computational module in the SSC API library.
    #
    # @param [int] module_index the index of the module
    # @return [Hash] containing information on computational modules available
    def module_info_by_index(module_index)
      info = nil

      the_module = SscFfi.ssc_module_entry(module_index)

      unless the_module == FFI::Pointer::NULL
        info = {}
        info["index"] = module_index
        info["name"] = SscFfi.ssc_entry_name(the_module)
        info["description"] = SscFfi.ssc_entry_description(the_module)
        info["version"] = SscFfi.ssc_entry_version(the_module)

        #params = {}
        #
        #done = false
        #i = 0
        #while !done
        #
        #end

        vars = {}

        done = false
        i = 0
        the_module_obj = SscFfi.ssc_module_create(info["name"])

        until done
          var_info = SscFfi.ssc_module_var_info(the_module_obj, i)
          if var_info == FFI::Pointer::NULL
            done = true
          else
            var = {}

            var["var_type"] = SscFfi.ssc_info_var_type(var_info)
            var["data_type"] = SscFfi.ssc_info_data_type(var_info)
            var["label"] = SscFfi.ssc_info_label(var_info)
            var["units"] = SscFfi.ssc_info_units(var_info)
            var["meta"] = SscFfi.ssc_info_meta(var_info)
            var["group"] = SscFfi.ssc_info_group(var_info)
            var["required"] = SscFfi.ssc_info_required(var_info)
            var["uihint"] = SscFfi.ssc_info_uihint(var_info)

            vars[SscFfi.ssc_info_name(var_info)] = var
            i += 1
          end

          info["variables"] = vars
        end

        SscFfi.ssc_module_free(the_module_obj)
      end

      info
    end

    # Returns info on a computational module in the SSC API library.
    #
    # @param [String] module_name the name of the module
    # @return [Hash] containing information on computational modules available
    def module_info_by_name(module_name)
      info = nil

      done = false
      i = 0
      until done
        info = module_info_by_index(i)
        (info.nil? || info["name"] == module_name) ? done = true : i += 1
      end

      info
    end

    # Sets array data in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the variable to set in the data object
    # @param [Array] values the array data to be assigned to the data_name variable in the data object
    # @return [nil]
    def set_array(data_obj, name, values)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL
      raise ArgumentError, "values must be an Array, found #{values.class.name}" unless values.is_a? Array

      value_ptr = FFI::MemoryPointer.new :float, values.length
      values.collect! { |value| value.to_f }
      value_ptr.write_array_of_float(values)
      SscFfi.ssc_data_set_array(data_obj, name, value_ptr, values.length)
    end

    # Retrieves array data from an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the variable to set in the data object
    # @return [Array] the array of values read from the data object
    def get_array(data_obj, name)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      the_length = FFI::MemoryPointer.new :int
      result = SscFfi.ssc_data_get_array(data_obj, name, the_length)
      result.read_array_of_float(the_length.read_int)
    end

    # Sets matrix data in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the variable to set in the data object
    # @param [Matrix] values the matrix data to be assigned to the data_name variable in the data object
    # @return [nil]
    def set_matrix(data_obj, name, values)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL
      raise ArgumentError, "values must be a Matrix object, found #{values.class.name}" unless values.is_a? Matrix

      matrix_ptr = FFI::MemoryPointer.new :pointer, (values.row_size * values.column_size)

      # ssc wants it as a 1-dimensional array, so flatten it
      matrix_ptr.write_array_of_float values.to_a.flatten

      SscFfi.ssc_data_set_matrix(data_obj, name, matrix_ptr, values.row_size, values.column_size)
    end

    # Retrieves matrix data from an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the variable to set in the data object
    # @return [Matrix] the matrix of values read from the data object
    def get_matrix(data_obj, name)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      row_count = FFI::MemoryPointer.new :int
      col_count = FFI::MemoryPointer.new :int

      raw_values = SscFfi.ssc_data_get_matrix(data_obj, name, row_count, col_count)
      the_values = raw_values.read_array_of_float(row_count.read_int * col_count.read_int)
      #rows = raw_values.read_array_of_pointer(row_count.read_int)

      m_rows = row_count.read_int
      m_cols = col_count.read_int

      rows = []
      (0..m_rows-1).each do |n|
        rows << the_values[n * m_cols, m_cols]
      end

      Matrix[*rows]
    end

    # Creates an SSC API data object.
    #
    # @return [FFI:Pointer] an SSC API data object
    def create_data_object
      SscFfi.ssc_data_create()
    end

    # Frees an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @return [nil]
    def free_data(data_obj)
      SscFfi.ssc_data_free(data_obj)
    end

    # Clears the entire object or a specific value in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [optional, String] name the name of the data field to clear
    # @return [nil]
    def clear_data(data_obj, name=nil)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      if name.nil?
        SscFfi.ssc_data_clear(data_obj)
      else
        SscFfi.ssc_data_unassign(data_obj, name)
      end
    end

    # Checks to see if a data field exists in an SSC API data object, and returns
    # its data type if it does or invalid if not.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [optional, String] name the name of the data value to clear
    # @return [Integer] the data type or invalid if field is not present
    def query_field(data_obj, name)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      SscFfi.ssc_data_query(data_obj, name)
    end

    # Sets a string data value in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the data value to set
    # @param [String] value the string value to set
    # @return [nil]
    def set_string(data_obj, name, value)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      SscFfi.ssc_data_set_string(data_obj, name, value)
    end

    # Retrieves a string data value in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the data value to set
    # @return [String] the string value
    def get_string(data_obj, name)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      SscFfi.ssc_data_get_string(data_obj, name)
    end

    # Sets a number data value in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [Numeric] name the name of the data value to set
    # @param [String] value the string value to set
    # @return [nil]
    def set_number(data_obj, name, value)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL
      raise ArgumentError, "Value must be numeric" unless value.is_a? Numeric

      SscFfi.ssc_data_set_number(data_obj, name, value.to_f)
    end

    # Retrieves a number data value in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @param [String] name the name of the data value to set
    # @return [Float, nil] the number value or nil if not found
    def get_number(data_obj, name)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      ptr = FFI::MemoryPointer.new :float
      result = SscFfi.ssc_data_get_number(data_obj, name, ptr)
      if result
        ptr.read_float
      else
        nil
      end
    end

    # Retrieves the names of all the data fields in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @return [Array] an array of strings containing the names of data fields
    def get_field_names(data_obj)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      data_names = []

      the_name = get_first_field(data_obj)
      until the_name.nil?
        data_names << the_name
        the_name = get_next_field(data_obj)
      end

      data_names
    end

    # Retrieves the name of the first data field in an SSC API data object,
    # or nil if there are no fields.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @return [String, nil] the name of the first data field or nil if none
    def get_first_field(data_obj)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      SscFfi.ssc_data_first(data_obj)
    end

    # Retrieves the names of all the data fields in an SSC API data object.
    #
    # @param [FFI::Pointer] data_obj the SSC API data object
    # @return [String, nil] the name of the next data field or nil if none
    def get_next_field(data_obj)
      raise ArgumentError, "data_obj cannot be nil" if data_obj.nil? || data_obj == FFI::Pointer::NULL

      SscFfi.ssc_data_next(data_obj)
    end

    # Creates an SSC API module object.
    #
    # @param [String] name the name of the computational module
    # @return [FFI:Pointer] an SSC API module object
    def create_module(name)
      SscApi::SscFfi.ssc_module_create(name)
    end

    # Frees an SSC API module object.
    #
    # @param [FFI::Pointer] module_object the SSC API module object (see #create_module)
    # @return [nil]
    def free_module(module_object)
      SscApi::SscFfi.ssc_module_free(module_object)
    end

    # Executes an SSC API module
    #
    # @param [FFI::Pointer] module_obj the SSC API module object (see #create_module)
    # @return [true, false] success
    def execute_module(module_obj, data_obj)
      result_code = SscApi::SscFfi.ssc_module_exec(module_obj, data_obj)
      !(result_code == SscApi::SSC_INVALID)
    end

    # Retrieves error messages from an SSC API module
    #
    # @param [FFI::Pointer] module_obj the SSC API module object (see #create_module)
    # @return [Array] an array of strings containing any error messages
    def get_module_errors(module_obj)
      the_errors = []
      idx = 1
      the_type = FFI::MemoryPointer.new :int
      the_time = FFI::MemoryPointer.new :float

      msg = SscApi::SscFfi.ssc_module_log(module_obj, 0, the_type, the_time)
      until msg.nil? do
        the_errors << msg
        msg = SscApi::SscFfi.ssc_module_log(module_obj, idx, the_type, the_time)
        idx = idx + 1
      end

      the_errors
    end

    # Turn on/of the status update messages from ssc
    #
    # @param [boolean] true to turn it on, false to turn it off
    def set_print(on_or_off=false)
      SscApi::SscFfi.ssc_module_exec_set_print(on_or_off ? 1 : 0)
    end
  end
end
