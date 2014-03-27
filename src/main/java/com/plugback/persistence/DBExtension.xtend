package com.plugback.persistence

import javax.persistence.EntityManager
import java.util.List
import com.plugback.reflection.ReflectionHelperImpl

class DBExtension<T> {
	
	Class<T> c
	
	EntityManager em
	
	def static <X> find(EntityManager db, Class<X> c){
		return new DBExtension<X>(c, db)
	}
	
	def static <T> findAll(EntityManager db, Class<T> c){
		return db.createQuery('''select x from «c.simpleName» x''', c).resultList as List<T>
	}
	
	protected new(Class<T> c, EntityManager em){
		this.em = em
		this.c = c
	}
	
	val private static queryBooleanOperator = new ThreadLocal<List<String>>
         
             
	
	def static void and(){
		queryBooleanOperator.get.add("and")
	}
	
	def static void or(){
		queryBooleanOperator.get.add("or")
	}
	
	def where((T) => void whereClause){
		
		queryBooleanOperator.set(newArrayList)
		
		val x = c.newInstance
		whereClause.apply(x)
		val fields = new ReflectionHelperImpl().getFieldsAndValues(x).filter[k, v| v != null]
		
		val wheres = <String>newArrayList()
		fields.forEach[k, v, index|
			wheres.add('''x.«k» = :p«index»''')
		]
		
		val completeWhereCluase = new StringBuilder
		if(wheres.size > 2)
			throw new IllegalArgumentException("Sorry, current where implementation supports only one boolean operator.")
		completeWhereCluase.append(wheres.head)
		if(wheres.size > 0){
			val ops = queryBooleanOperator.get
			ops.forEach[op, index | completeWhereCluase.append(''' «op» «wheres.get(index + 1)»''') ]
			
		}
		
		
		
		
		val query = '''select x from «c.simpleName» x where «completeWhereCluase.toString»'''
		val tq = em.createQuery(query, c)
		fields.forEach[k, v, index|
			tq.setParameter('''p«index»''', v)
		]
						
		queryBooleanOperator.remove
		
		return tq
	}
	
}