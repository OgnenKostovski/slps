package org.planet_sl.apimigration.benchmark.jdom.wrapped_as_xom;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;

import org.planet_sl.apimigration.benchmark.anno.Issue;
import org.planet_sl.apimigration.benchmark.anno.MapsTo;
import org.planet_sl.apimigration.benchmark.anno.Progress;
import org.planet_sl.apimigration.benchmark.anno.Solution;
import org.planet_sl.apimigration.benchmark.anno.Unresolved;
import org.planet_sl.apimigration.benchmark.anno.Wrapping;
import org.planet_sl.apimigration.benchmark.anno.Progress.Status;
import org.planet_sl.apimigration.benchmark.anno.Solution.Strategy;
import org.planet_sl.apimigration.benchmark.anno.Unresolved.XML;

@SuppressWarnings("unchecked")
@MapsTo("org.jdom.Attribute")
public class Attribute extends Node {

	@MapsTo("int")
	public static class Type {
		@Wrapping
		private int type;

		@Wrapping
		Type(int type) {
			this.type = type;
		}

		public static final Attribute.Type CDATA = new Type(
				org.jdom.Attribute.CDATA_TYPE);
		public static final Attribute.Type UNDECLARED = new Type(
				org.jdom.Attribute.UNDECLARED_TYPE);
		public static final Attribute.Type ID = new Type(
				org.jdom.Attribute.ID_TYPE);
		public static final Attribute.Type IDREF = new Type(
				org.jdom.Attribute.IDREF_TYPE);
		public static final Attribute.Type IDREFS = new Type(
				org.jdom.Attribute.IDREFS_TYPE);
		public static final Attribute.Type NMTOKEN = new Type(
				org.jdom.Attribute.NMTOKEN_TYPE);
		public static final Attribute.Type NMTOKENS = new Type(
				org.jdom.Attribute.NMTOKENS_TYPE);
		public static final Attribute.Type NOTATION = new Type(
				org.jdom.Attribute.NOTATION_TYPE);
		public static final Attribute.Type ENTITY = new Type(
				org.jdom.Attribute.ENTITY_TYPE);
		public static final Attribute.Type ENTITIES = new Type(
				org.jdom.Attribute.ENTITIES_TYPE);
		public static final Attribute.Type ENUMERATION = new Type(
				org.jdom.Attribute.ENUMERATED_TYPE);

		@Progress(value = Status.OK, comment = "")
		@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
		public String getName() {
			switch (type) {
			case org.jdom.Attribute.UNDECLARED_TYPE:
				return "UNDECLARED";
			case org.jdom.Attribute.CDATA_TYPE:
				return "CDATA";
			case org.jdom.Attribute.ID_TYPE:
				return "ID";
			case org.jdom.Attribute.IDREF_TYPE:
				return "IDREF";
			case org.jdom.Attribute.IDREFS_TYPE:
				return "IDREFS";
			case org.jdom.Attribute.NMTOKEN_TYPE:
				return "NMTOKEN";
			case org.jdom.Attribute.NMTOKENS_TYPE:
				return "NMTOKENS";
			case org.jdom.Attribute.NOTATION_TYPE:
				return "NOTATION";
			case org.jdom.Attribute.ENTITY_TYPE:
				return "ENTITY";
			case org.jdom.Attribute.ENTITIES_TYPE:
				return "ENTITIES";
			case org.jdom.Attribute.ENUMERATED_TYPE:
				return "ENUMERATION";
			default:
				throw new AssertionError(
						"bug in wrapping JDOM as XOM: unexpected attribute type: "
								+ type);
			}
		}

		@Progress(value = Status.DONTCARE, comment = "toString is for debugging")
		@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
		@Override
		public String toString() {
			return "[Attribute.Type." + getName() + "]";
		}

		@Progress(value = Status.DONTCARE, comment = "opaque")
		@Solution(value = Strategy.DELEGATE, comment = "")
		public int hashCode() {
			return type;
		}

		@Progress(value = Status.OK, comment = "")
		@Solution(value = Strategy.DELEGATE, comment = "")
		public boolean equals(Object o) {
			if (!(o instanceof Type)) {
				return false;
			}
			return type == ((Type) o).type;
		}
	}

	@Wrapping
	org.jdom.Attribute attribute;

	@Wrapping
	Attribute(org.jdom.Attribute attribute) {
		this.attribute = attribute;
	}

	// XOM api starts here.

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#clone()")
	public Attribute(Attribute attribute) {
		this((org.jdom.Attribute) attribute.attribute.clone());
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Issue.Pre(value = "XOM allows colonized names in the first argument whereas JDOM does not", resolved = true)
	@Issue.Doc("XOM docs say first arg is localName, however, tests send colonized names")
	@MapsTo("org.jdom.Attribute(String,String)")
	public Attribute(String name, String value) {
		int index = name.indexOf(":");
		String prefix = "";
		String localName = name;
		if (index != -1) {
			prefix = name.substring(0, index);
			localName = name.substring(index + 1, name.length());
		}
		if (prefix.equals("xml")) {
			throw new NamespaceConflictException(
					"creating xml: prefix attribute without proper namespace");
		}
		if (prefix.equals("xmlns")) {
			throw new IllegalNameException("creating xmlns attribute", name);
		}
		try {
			attribute = new org.jdom.Attribute(localName, value);
		} catch (org.jdom.IllegalNameException e) {
			throw new IllegalNameException(e, localName);
		} catch (org.jdom.IllegalDataException e) {
			throw new IllegalDataException(e, value);
		}
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute(String,String,int)")
	public Attribute(String localName, String value, Attribute.Type type) {
		this(new org.jdom.Attribute(localName, value, ((Type) type).type));
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Issue.Pre(value = "XOM allows colons in names, JDOM does not", resolved = true)
	@Issue.Throws(value = "NamespaceConflictException is not thrown by JDOM", resolved = true)
	@MapsTo("org.jdom.Attribute(String,String,org.jdom.Namespace)")
	public Attribute(String name, String URI, String value) {
		int index = name.indexOf(":");
		String prefix = "";
		String localName = name;
		if (index != -1) {
			prefix = name.substring(0, index);
			localName = name.substring(index + 1, name.length());
		}
		if (prefix.equals("xml")
				&& !URI.equals(org.jdom.Namespace.XML_NAMESPACE.getURI())) {
			throw new NamespaceConflictException(
					"invalid namespace for xml: attribute");
		}
		if (!prefix.equals("xml")
				&& URI.equals(org.jdom.Namespace.XML_NAMESPACE.getURI())) {
			throw new NamespaceConflictException(
					"invalid prefix in combination with xml namespace");
		}
		try {
			attribute = new org.jdom.Attribute(localName, value,
					org.jdom.Namespace.getNamespace(prefix, URI));
		} catch (org.jdom.IllegalNameException e) {
			throw new IllegalNameException(e, localName);
		}
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Issue.Pre(value = "XOM allows colons in names, JDOM does not", resolved = true)
	@Issue.Throws(value = "NamespaceConflictException is not thrown by JDOM", resolved = true)
	@MapsTo("org.jdom.Attribute(String,String,int,org.jdom.Namespace)")
	public Attribute(String name, String URI, String value, Attribute.Type type) {
		int index = name.indexOf(":");
		String prefix = "";
		String localName = name;
		if (index != -1) {
			prefix = name.substring(0, index);
			localName = name.substring(index, name.length());
		}
		if (prefix.equals("xml")
				&& !URI.equals(org.jdom.Namespace.XML_NAMESPACE.getURI())) {
			throw new NamespaceConflictException(
					"invalid namespace for xml: attribute");
		}
		if (!prefix.equals("xml")
				&& URI.equals(org.jdom.Namespace.XML_NAMESPACE.getURI())) {
			throw new NamespaceConflictException(
					"invalid prefix in combination with xml namespace");
		}
		try {
			attribute = new org.jdom.Attribute(localName, value, type.type,
				org.jdom.Namespace.getNamespace(prefix, URI));
		} 
		catch (org.jdom.IllegalNameException e) {
			throw new IllegalNameException(e, localName);
		}
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#clone()")
	public Node copy() {
		return new Attribute((org.jdom.Attribute) attribute.clone());
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#getName()")
	public String getLocalName() {
		return attribute.getName();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#getNamespacePrefix()")
	public String getNamespacePrefix() {
		return attribute.getNamespacePrefix();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#getNamespaceURI()")
	public String getNamespaceURI() {
		return attribute.getNamespaceURI();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#getQualifiedName()")
	public String getQualifiedName() {
		return attribute.getQualifiedName();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#getAttributeType()")
	public Type getType() {
		return new Type(attribute.getAttributeType());
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#getValue()")
	public String getValue() {
		return attribute.getValue();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#setName()")
	public void setLocalName(String localName) {
		try {
			attribute.setName(localName);
		} catch (org.jdom.IllegalNameException e) {
			throw new IllegalNameException(e, localName);
		}
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Issue.Throws(value = "xom throws NamespaceConflictException (not IllegalNameException)", resolved = true)
	@MapsTo("org.jdom.Attribute#setNamespace(Namespace)")
	public void setNamespace(String prefix, String uri) {
		if (uri != null) {
			try {
				new URI(uri);
			} catch (URISyntaxException e) {
				throw new MalformedURIException(e, uri);
			}
		}
		try {
			attribute
					.setNamespace(org.jdom.Namespace.getNamespace(prefix, uri));
		} catch (org.jdom.IllegalNameException e) {
			throw new NamespaceConflictException(e, uri);
		}
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Issue.Throws(value = "XOM Attribute.Type can be null, but not outof bounds as in JDOM (which throws IllegalDataException", resolved = true)
	@MapsTo("org.jdom.Attribute#setAttributeType(int)")
	public void setType(Type type) {
		if (type == null) {
			throw new NullPointerException("type must not be null");
		}
		attribute.setAttributeType(((Type) type).type);
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@MapsTo("org.jdom.Attribute#setValue()")
	public void setValue(String value) {
		try {
			attribute.setValue(value);
		} catch (org.jdom.IllegalDataException e) {
			throw new IllegalDataException(e, value);
		}
	}

	@Progress(value = Status.NEEDSWORK, comment = "is a debugging aid")
	@Solution(value = Strategy.CLONE, comment = "")
	@Issue.Post(value = "JDOM's escaping is different from XOM's", resolved = true)
	@Unresolved(XML.Escaping)
	@Override
	@MapsTo("")
	public String toXML() {
		return attribute.getName()
				+ "=\""
				+ new org.jdom.output.XMLOutputter()
						.escapeAttributeEntities(attribute.getValue())
						.replaceAll("&#xA", "&#x0A") 
						.replaceAll("&#xD", "&#x0D") 
						.replaceAll("&#x9", "&#x09") + 
						"\"";
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#detach()")
	public void detach() {
		attribute.detach();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.MACRO, comment = "")
	@MapsTo("")
	public String getBaseURI() {
		org.jdom.Element parent = attribute.getParent();
		if (parent == null) {
			return "";
		}
		return new Element(parent).getBaseURI();
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#getDocument()")
	public Document getDocument() {
		return new Document(attribute.getDocument());
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#getParent()")
	public ParentNode getParent() {
		org.jdom.Element parent = attribute.getParent();
		if (parent == null) {
			return null;
		}
		return new Element(attribute.getParent());
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.xpath.XPath#selectNodes(Object)")
	public Nodes query(String query, XPathContext namespaces) {
		try {
			org.jdom.xpath.XPath xpath = org.jdom.xpath.XPath
					.newInstance(query);
			for (Object o : namespaces.namespaces) {
				xpath.addNamespace((org.jdom.Namespace) o);
			}
			List list = xpath.selectNodes(this.attribute);
			return new Nodes(list);
		} catch (org.jdom.JDOMException e) {
			throw new XPathException(e.getMessage(), e.getCause());
		}
	}

	@Progress(value = Status.NEEDSWORK, comment = "")
	@Solution(value = Strategy.ADVANCED_DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.xpath.XPath#selectNodes(Object)")
	public Nodes query(String query) {
		try {
			org.jdom.xpath.XPath xpath = org.jdom.xpath.XPath
					.newInstance(query);
			List list = xpath.selectNodes(this.attribute);
			return new Nodes(list);
		} catch (org.jdom.JDOMException e) {
			throw new XPathException(e.getMessage(), e.getCause());
		}
	}

	@Progress(value = Status.OK, comment = "")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#equals(Object)")
	public boolean equals(Object o) {
		if (!(o instanceof Attribute)) {
			return false;
		}
		return attribute.equals(((Attribute) o).attribute);
	}

	@Progress(value = Status.OK, comment = "opaque")
	@Solution(value = Strategy.DELEGATE, comment = "")
	@Override
	@MapsTo("org.jdom.Attribute#hashCode()")
	public int hashCode() {
		return attribute.hashCode();
	}

	
	@Progress(value = Status.DONTCARE, comment = "")
	@Solution(value = Strategy.CLONE, comment = "")
	@Override
	public String toString() {
		return "";
	}
	
}