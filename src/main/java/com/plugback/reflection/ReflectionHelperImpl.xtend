package com.plugback.reflection

import com.plugback.active.interfaces.GenerateInterface
import com.thoughtworks.paranamer.BytecodeReadingParanamer
import java.io.File
import java.lang.reflect.Field
import java.lang.reflect.Method
import java.lang.reflect.Modifier
import java.util.List
import java.util.Map

@GenerateInterface
class ReflectionHelperImpl {

	override Field[] getAllFields(Class<?> c) {
		val fields = <Field>newArrayList
		val superclasses = c.allSuperClasses
		superclasses.forEach[fields.addAll(declaredFields)]
		fields.addAll(c.declaredFields)
		fields.forEach[setAccessible(true)]
		fields
	}

	override List<Class<?>> getAllSuperClasses(Class<?> c) {
		val classes = newArrayList
		var superclass = c.superclass
		while (superclass != null && !superclass.equals(Object)) {
			classes.add(superclass);
			superclass = superclass.superclass
		}
		return classes;
	}

	override Class<?>[] getAllInterfaces(Class<?> c) {
		val classes = c.allSuperClasses
		classes.add(c)
		val interfaces = newArrayList
		classes.forEach[interfaces.addAll(it.interfaces)]
		interfaces
	}

	override Map<Field, Object> getFieldsAndValues(Object t) {
		val af = t.class.allFields
		return af.toInvertedMap[get(t)]
	}

	override Boolean implementsInterface(Class<?> c, Class<?> interfaceClass) {
		c.allInterfaces.filter[it == interfaceClass].size > 0
	}

	override Class<?>[] getPackageClasses(String packageName) {
		val classLoader = Thread.currentThread.contextClassLoader
		val path = packageName.replace('.', '/')
		val resources = classLoader.getResources(path)

		val dirs = <File>newArrayList
		while (resources.hasMoreElements()) {
			val resource = resources.nextElement
			dirs.add(new File(resource.file))
		}
		val classes = newArrayList
		for (File directory : dirs) {
			classes.addAll(directory.findClasses(packageName))
		}

		return classes
	}
	
	override Class<?>[] getPackageConcreteClasses(String packageName) {
		return packageName.packageClasses.filter[Modifier.isAbstract(modifiers)]
	}

	/**
	 * Recursive method used to find all classes in a given directory and
	 * subdirs.
	 * 
	 * @param directory
	 *            The base directory
	 * @param packageName
	 *            The package name for classes found inside the base directory
	 * @return The classes
	 * @throws ClassNotFoundException
	 */
	private static def Class<?>[] findClasses(File directory, String packageName) {
		val classes = newArrayList
		if (!directory.exists()) {
			return classes
		}
		directory.listFiles.forEach [
			if (isDirectory)
				classes.addAll(findClasses(it, packageName + "." + name))
			else if (name.endsWith(".class"))
				classes.add(Class.forName(packageName + '.' + name.substring(0, name.length - 6)))
		]
		return classes;
	}
	
	override String[] getParameterNames(Method method) {
		val paranamer = new BytecodeReadingParanamer
		val parameterNames = paranamer.lookupParameterNames(method, false)
		if (parameterNames == null)
			return newArrayList
		return parameterNames
	}
	
	override Method[] getAllMethods(Class<?> c){
		val methods = <Method>newHashSet
		val classes = <Class<?>> newArrayList
		classes.addAll(c.allSuperClasses)
		classes.add(c)	
		classes.forEach[methods.addAll(declaredMethods)]
		methods.forEach[setAccessible(true)]
		return methods;
	}
}
