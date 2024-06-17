import xml.etree.ElementTree as ET


class HPXML:
    def __init__(self, xml_path) -> None:
        self.tree = ET.parse(xml_path)
        self.root = self.tree.getroot()
        self.namespace_uri = self.root.tag.split('{')[1].split('}')[0]
        self.ns = {'ns': self.namespace_uri}
        ET.register_namespace('', self.namespace_uri)

    def findall(self, element_name, parent=None):
        if parent is None:
            return self.root.findall(f"ns:{element_name}", self.ns)
        else:
            return parent.findall(f"ns:{element_name}", self.ns)

    def create_elements_as_needed(self, parent, element_names):
        current_parent = parent
        for element_name in element_names:
            element = current_parent.find(f"ns:{element_name}", self.ns)
            if element is None:
                element = ET.SubElement(current_parent, f"ns:{element_name}")
            current_parent = element
        return current_parent
