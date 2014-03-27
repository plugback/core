package com.plugback.typescript

import com.plugback.reflection.ReflectionHelperImpl

class ModelsGenerator {

	def String generateTypeScriptModelsFor(Class<?> ... cs) {

		val extension rh = new ReflectionHelperImpl

		val ts = new StringBuilder

		cs.forEach [ c |
			val extended = c.superclass
			val parentGenerated = cs.contains(extended)
			val ext = if (parentGenerated) '''extends «extended.simpleName» ''' else ""
			ts.append(
				'''interface «c.simpleName» «ext»{
					''')
			c.allFields.forEach [ f |
				val ans = f.annotations
				if (ans.filter [ a |
					val name = a.annotationType.simpleName
					name == "Property" || name == "ReadOnly"
				].size > 0) {
					val ct = f.type.name
					val t = switch (ct) {
						case "java.lang.String": "string"
						case "java.lang.Integer": "number"
						case "java.lang.int": "number"
						case "java.lang.Long": "number"
						case "java.lang.long": "number"
						case "java.lang.Boolean": "boolean"
						case "java.lang.boolean": "boolean"
						default: f.type.simpleName
					}
					ts.append(
						'''	«f.name» : «t»;
							''')
				}
			]
			ts.append(
				'''
					}
					
				''')
		]

		return ts.toString
	}

}
