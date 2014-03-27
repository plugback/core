package com.plugback.utils.persistence

import com.google.common.collect.HashBasedTable
import com.plugback.reflection.ReflectionHelper
import com.plugback.reflection.ReflectionHelperImpl
import java.util.Calendar
import java.util.Date
import java.util.Map
import java.util.Random
import javax.persistence.EntityManager
import javax.persistence.EntityTransaction
import javax.persistence.FlushModeType
import javax.persistence.LockModeType
import javax.persistence.Parameter
import javax.persistence.TemporalType
import javax.persistence.TypedQuery
import javax.persistence.criteria.CriteriaDelete
import javax.persistence.criteria.CriteriaQuery
import javax.persistence.criteria.CriteriaUpdate

class InMemoryEntityManager implements EntityManager {

	new() {
		rh = new ReflectionHelperImpl
	}

	def <T> all(Class<T> c) {
		return storage.values.filter[o|o.class == c]
	}

	var storage = HashBasedTable.create

	boolean opened = false

	ReflectionHelper rh

	def storage() {
		return this.storage
	}

	override clear() {
		storage.clear
	}

	override close() {
		storage.clear
	}

	override contains(Object entity) {
		return storage.values.contains(entity)
	}

	override <T> createEntityGraph(Class<T> rootType) {
	}

	override createEntityGraph(String graphName) {
	}

	override createNamedQuery(String name) {
	}

	override <T> createNamedQuery(String name, Class<T> resultClass) {
	}

	override createNamedStoredProcedureQuery(String name) {
	}

	override createNativeQuery(String sqlString) {
	}

	override createNativeQuery(String sqlString, Class resultClass) {
	}

	override createNativeQuery(String sqlString, String resultSetMapping) {
	}

	override createQuery(String qlString) {
	}

	override <T> createQuery(CriteriaQuery<T> criteriaQuery) {
	}

	override createQuery(CriteriaUpdate updateQuery) {
	}

	override createQuery(CriteriaDelete deleteQuery) {
	}

	override <T> createQuery(String qlString, Class<T> resultClass) {
		return new FakeTypedQuery(this)
	}

	override createStoredProcedureQuery(String procedureName) {
	}

	override createStoredProcedureQuery(String procedureName, Class... resultClasses) {
	}

	override createStoredProcedureQuery(String procedureName, String... resultSetMappings) {
	}

	override detach(Object entity) {
	}

	override <T> find(Class<T> entityClass, Object primaryKey) {
		return storage.get(entityClass, primaryKey) as T
	}

	override <T> find(Class<T> entityClass, Object primaryKey, Map<String, Object> properties) {
	}

	override <T> find(Class<T> entityClass, Object primaryKey, LockModeType lockMode) {
	}

	override <T> find(Class<T> entityClass, Object primaryKey, LockModeType lockMode, Map<String, Object> properties) {
	}

	override flush() {
	}

	override getCriteriaBuilder() {
	}

	override getDelegate() {
	}

	override getEntityGraph(String graphName) {
	}

	override <T> getEntityGraphs(Class<T> entityClass) {
	}

	override getEntityManagerFactory() {
	}

	override getFlushMode() {
	}

	override getLockMode(Object entity) {
	}

	override getMetamodel() {
	}

	override getProperties() {
	}

	override <T> getReference(Class<T> entityClass, Object primaryKey) {
		return storage.get(entityClass, primaryKey) as T
	}

	override getTransaction() {
		opened = true
		return new FakeEntityTransaction
	}

	override isJoinedToTransaction() {
		return true
	}

	override isOpen() {
		return opened
	}

	override joinTransaction() {
	}

	override lock(Object entity, LockModeType lockMode) {
	}

	override lock(Object entity, LockModeType lockMode, Map<String, Object> properties) {
	}

	override <T> merge(T entity) {
		val id = new Random().nextLong
		try {
			val currentId = rh.getFieldsAndValues(entity).get("id")
			if (currentId == null) {
				rh.getAllFields(entity.class).filter[name == "id"].head.set(entity, id)
			}
		} catch (Exception e) {
		}
		storage.put(entity.class, id, entity)
		return entity
	}

	override persist(Object entity) {
		merge(entity)
	}

	override refresh(Object entity) {
	}

	override refresh(Object entity, Map<String, Object> properties) {
	}

	override refresh(Object entity, LockModeType lockMode) {
	}

	override refresh(Object entity, LockModeType lockMode, Map<String, Object> properties) {
	}

	override remove(Object entity) {
	}

	override setFlushMode(FlushModeType flushMode) {
	}

	override setProperty(String propertyName, Object value) {
	}

	override <T> unwrap(Class<T> cls) {
	}

}

class FakeEntityTransaction implements EntityTransaction {

	var opened = false

	override begin() {
		opened = true
	}

	override commit() {
		opened = false
	}

	override getRollbackOnly() {
		return true
	}

	override isActive() {
		return opened
	}

	override rollback() {
	}

	override setRollbackOnly() {
	}

}

@SuppressWarnings("all")
class FakeTypedQuery<T> implements TypedQuery<T> {

	@Property val setParameters = <String>newArrayList

	val InMemoryEntityManager mem

	String property

	Object value

	new(InMemoryEntityManager mem) {
		this.mem = mem
	}

	override getResultList() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getSingleResult() {
		return mem.storage.values.filter[x|new ReflectionHelperImpl().getFieldsAndValues(x).get(property) == value].head as T
	}

	override setFirstResult(int arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setFlushMode(FlushModeType arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setHint(String arg0, Object arg1) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setLockMode(LockModeType arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setMaxResults(int arg0) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override <T> FakeTypedQuery setParameter(Parameter<T> arg0, T arg1) {
		_setParameters.add(arg0 + " = " + arg1)
		return this
	}

	override setParameter(String property, Object value) {
		_setParameters.add(property + " = " + value)
		this.property = property
		this.value = value
		return this
	}

	override setParameter(int arg0, Object arg1) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setParameter(Parameter<Calendar> arg0, Calendar arg1, TemporalType arg2) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setParameter(Parameter<Date> arg0, Date arg1, TemporalType arg2) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setParameter(String arg0, Calendar arg1, TemporalType arg2) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setParameter(String arg0, Date arg1, TemporalType arg2) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setParameter(int arg0, Calendar arg1, TemporalType arg2) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override setParameter(int arg0, Date arg1, TemporalType arg2) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override executeUpdate() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getFirstResult() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getFlushMode() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getHints() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getLockMode() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getMaxResults() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getParameter(String name) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getParameter(int position) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override <T> getParameter(String name, Class<T> type) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override <T> getParameter(int position, Class<T> type) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override <T> getParameterValue(Parameter<T> param) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getParameterValue(String name) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getParameterValue(int position) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override getParameters() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override isBound(Parameter<?> param) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

	override <T> unwrap(Class<T> cls) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}

}
