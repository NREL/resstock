# frozen_string_literal: true

class Validator
  def self.run_validator(hpxml_doc, stron_path)
    errors = []
    doc = XMLHelper.parse_file(stron_path)
    XMLHelper.get_elements(doc, '/sch:schema/sch:pattern/sch:rule').each do |rule|
      context_xpath = XMLHelper.get_attribute_value(rule, 'context').gsub('h:', '')

      begin
        context_elements = hpxml_doc.xpath(context_xpath)
      rescue
        fail "Invalid xpath: #{context_xpath}"
      end
      next if context_elements.empty? # Skip if context element doesn't exist

      XMLHelper.get_elements(rule, 'sch:assert').each do |assert_element|
        assert_test = XMLHelper.get_attribute_value(assert_element, 'test').gsub('h:', '')

        context_elements.each do |context_element|
          begin
            xpath_result = context_element.xpath(assert_test)
          rescue
            fail "Invalid xpath: #{assert_test}"
          end
          next if xpath_result # check if assert_test is false

          assert_value = assert_element.children.text # the value of sch:assert
          error_message = assert_value.gsub(': ', ": #{context_xpath}: ") # insert context xpath into the error message
          errors << error_message
        end
      end
    end

    return errors
  end
end
