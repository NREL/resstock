import xml.etree.ElementTree as ET
import os


class XMLHelper:
    @staticmethod
    def add_element(parent, element_name, value=None, datatype=None, defaulted=False):
        return XMLHelper.insert_element(parent, element_name, -1, value, datatype, defaulted)

    #   def self.get_values(parent, element_name, datatype)
    #     values = []
    #     parent.xpath(element_name).each do |value|
    #     value = value.text

    #     if datatype == :integer
    #         value = to_integer_or_nil(value, parent, element_name)
    #     elsif datatype == :float
    #         value = to_float_or_nil(value, parent, element_name)
    #     elsif datatype == :boolean
    #         value = to_boolean_or_nil(value, parent, element_name)
    #     elsif datatype != :string
    #         fail 'Unexpected datatype.'
    #     end

    #     values << value
    #     end

    #     return values
    # end
    # Convert this ruby code to python
    @staticmethod
    def get_values(parent, element_name, datatype):
        values = []
        for value in parent.findall(element_name):
            value = value.text
            if datatype == 'integer':
                value = XMLHelper.to_integer(value)
            elif datatype == 'float':
                value = XMLHelper.to_float(value)
            elif datatype == 'boolean':
                value = XMLHelper.to_boolean(value)
            elif datatype != 'string':
                raise Exception('Unexpected datatype.')
            values.append(value)
        return values

    @staticmethod
    def insert_element(parent, element_name, index=0, value=None, datatype=None, defaulted=False):
        added = ET.Element(element_name)
        if index == -1:
            parent.append(added)
        else:
            parent.insert(index, added)

        if value is not None:
            if datatype == 'integer':
                value = XMLHelper.to_integer(value)
            elif datatype == 'float':
                value = XMLHelper.to_float(value)
            elif datatype == 'boolean':
                value = XMLHelper.to_boolean(value)
            elif datatype != 'string':
                raise Exception('Unexpected datatype')
            added.text = str(value)

        if defaulted:
            XMLHelper.add_attribute(added, 'dataSource', 'software')

        return added

    @staticmethod
    def add_extension(parent, element_name, value=None, datatype=None, defaulted=False):
        extension = XMLHelper.create_elements_as_needed(parent, ['extension'])
        return XMLHelper.add_element(extension, element_name, value, datatype, defaulted)

    @staticmethod
    def create_elements_as_needed(parent, element_names):
        current_parent = parent
        for element_name in element_names:
            element = XMLHelper.get_element(current_parent, element_name)
            if element is None:
                XMLHelper.add_element(current_parent, element_name)
            current_parent = XMLHelper.get_element(current_parent,
                                                   element_name)
        return current_parent

    @staticmethod
    def get_element(parent, element_name):
        return parent.find(element_name)

    @staticmethod
    def get_elements(parent, element_name):
        return parent.findall(element_name)

    @staticmethod
    def add_attribute(element, attr_name, attr_val):
        element.set(attr_name, attr_val)

    @staticmethod
    def get_attribute_value(element, attr_name):
        return element.get(attr_name)

    @staticmethod
    def create_doc(version=None, encoding=None, standalone=None):
        xml_declaration = '<?xml version="{}" encoding="{}" standalone="{}"?>'.format(
            version or '1.0', encoding or 'UTF-8', standalone or 'no')
        return ET.ElementTree(ET.Element('root')), xml_declaration

    @staticmethod
    def parse_file(hpxml_path):
        tree = ET.parse(hpxml_path)
        return tree

    @staticmethod
    def write_file(doc, out_path):
        if not os.path.exists(os.path.dirname(out_path)):
            os.makedirs(os.path.dirname(out_path))
        doc.write(out_path, encoding='utf-8', xml_declaration=True)

    @staticmethod
    def to_float(value):
        try:
            return float(value)
        except ValueError:
            raise Exception(f"Cannot convert '{value}' to float.")

    @staticmethod
    def to_integer(value):
        try:
            value = float(value)
        except ValueError:
            raise Exception(f"Cannot convert '{value}' to integer.")
        if value.is_integer():
            return int(value)
        else:
            raise Exception(f"Cannot convert '{value}' to integer.")

    @staticmethod
    def to_boolean(value):
        str_value = str(value).lower()
        if str_value in ['true', '1']:
            return True
        elif str_value in ['false', '0']:
            return False
        else:
            raise Exception(f"Cannot convert '{value}' to boolean.")
