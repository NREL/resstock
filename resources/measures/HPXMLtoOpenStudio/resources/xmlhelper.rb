require 'rexml/document'
require 'rexml/xpath'

class XMLHelper

  # Adds the child element with 'element_name' and sets its value. Returns the
  # child element.
  def self.add_element(parent, element_name, value=nil)
    added = nil
    element_name.split("/").each do |name|
      added = REXML::Element.new(name)
      parent << added
      parent = added
    end
    if not value.nil?
      added.text = value
    end
    return added
  end
  
  # Deletes the child element with element_name. Returns the deleted element.
  def self.delete_element(parent, element_name)
    element = nil
    begin
      last_element = element
      element = parent.elements.delete(element_name)
    end while !element.nil?
    return last_element
  end
  
  # Returns the value of 'element_name' in the parent element or nil.
  def self.get_value(parent, element_name)
    val = parent.elements[element_name]
    if val.nil?
      return val
    end
    return val.text
  end  
  
  # Returns true if the element exists.
  def self.has_element(parent, element_name)
    element_name.split("/").each do |name|
      element = parent.elements[name]
      return false if element.nil?
      parent = element
    end
    return true
  end
  
  # Returns the attribute added
  def self.add_attribute(element, attr_name, attr_val)
    attr_val = self.valid_attr(attr_val).to_s
    added = element.add_attribute(attr_name, attr_val)
    return added
  end
  
  def self.valid_attr(attr)
    attr = attr.to_s
    attr = attr.gsub(" ", "_")
    attr = attr.gsub("|", "_")
    return attr
  end
  
  # Copies the element if it exists
  def self.copy_element(dest, src, element_name, backup_val=nil)
    return if src.nil?
    element = src.elements[element_name]
    if not element.nil?
      dest << element.dup
    elsif not backup_val.nil?
      # Element didn't exist in src, assign backup value instead
      add_element(dest, element_name.split("/")[-1], backup_val)
    end
  end  
  
  # Copies the multiple elements
  def self.copy_elements(dest, src, element_name)
    return if src.nil?
    if not src.elements[element_name].nil?
      src.elements.each(element_name) do |el|
        dest << el.dup
      end
    end
  end
  
  def self.validate(doc, xsd_path, runner=nil)
    begin
      require 'nokogiri'
      xsd = Nokogiri::XML::Schema(File.open(xsd_path))
      doc = Nokogiri::XML(doc)
      return xsd.validate(doc)
    rescue LoadError
      if not runner.nil?
        runner.registerWarning("Could not load nokogiri, no HPXML validation performed.")
      end
      return []
    end
  end
  
  def self.write_file(doc, out_path)
    # Write XML file
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    formatter.width = 1000
    File.open(out_path, 'w') do |f|
      formatter.write(doc, f)
    end
  end  
  
end

def Boolean(val)
  if val.nil?
    raise TypeError.new("can't convert nil into Boolean")
  end
  return val.downcase.to_s == "true"
end