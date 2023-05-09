# frozen_string_literal: true

class XMLValidator
  def self.get_schema_validator(schema_path)
    return OpenStudio::XMLValidator.new(schema_path)
  end

  def self.validate_against_schema(hpxml_path, validator, errors = [], warnings = [])
    # Validate against XSD
    validator.validate(hpxml_path)
    validator.errors.each do |e|
      next unless e.logMessage.count(':') >= 2

      # Clean up message
      msg_txt = e.logMessage.split(':')[2..-1].join(':').strip
      msg_txt = msg_txt.gsub("{#{HPXML::NameSpace}}", '').gsub("\n", '')
      errors.append(msg_txt)
    end
    warnings += validator.warnings.map { |w| w.logMessage }
    return errors, warnings
  end

  def self.get_schematron_validator(schematron_path)
    # First create XSLT at our specified output path to avoid possible errors due
    # to https://github.com/NREL/OpenStudio/issues/4824.
    xslt_dir = Dir.mktmpdir('xmlvalidation-')
    OpenStudio::XMLValidator::schematronToXslt(schematron_path, xslt_dir)
    xslt_path = File.join(xslt_dir, File.basename(schematron_path, '.xml') + '_stylesheet.xslt')

    return OpenStudio::XMLValidator.new(xslt_path)
  end

  def self.validate_against_schematron(hpxml_path, validator, hpxml_doc, errors = [], warnings = [])
    # Validate against Schematron doc
    validator.validate(hpxml_path)
    if validator.fullValidationReport.is_initialized
      report_doc = Oga.parse_xml(validator.fullValidationReport.get)

      # Parse validation report for user-friendly errors/warnings
      current_context = nil
      current_context_idx = 0
      XMLHelper.get_elements(report_doc, '//svrl:schematron-output/svrl:*').each do |n|
        if n.name == 'fired-rule'
          # Keep track of current context
          new_context = XMLHelper.get_attribute_value(n, 'context')
          if new_context == current_context
            current_context_idx += 1
          else
            current_context = new_context
            current_context_idx = 0
          end
        elsif n.name == 'failed-assert' || n.name == 'successful-report'
          # Error
          msg_txt = XMLHelper.get_value(n, 'svrl:text', :string)

          # Try to retrieve SystemIdentifier
          context_element = hpxml_doc.xpath(current_context.gsub('h:', ''))[current_context_idx]
          sys_id = XMLHelper.get_attribute_value(XMLHelper.get_element(context_element, 'SystemIdentifier'), 'id')
          if sys_id.nil?
            # Keep checking parent elements
            context_element.each_ancestor do |parent_element|
              sys_id = XMLHelper.get_attribute_value(XMLHelper.get_element(parent_element, 'SystemIdentifier'), 'id')
              break unless sys_id.nil?
            end
          end
          sys_id_string = ", id: \"#{sys_id}\"" unless sys_id.nil?

          full_msg = "#{msg_txt} [context: #{current_context.gsub('h:', '')}#{sys_id_string}]"
          if n.name == 'failed-assert'
            errors.append(full_msg)
          elsif n.name == 'successful-report'
            warnings.append(full_msg)
          end
        end
      end
    end
    return errors, warnings
  end
end
