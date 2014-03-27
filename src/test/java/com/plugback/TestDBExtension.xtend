package com.plugback

import com.plugback.utils.persistence.FakeTypedQuery
import com.plugback.utils.persistence.InMemoryEntityManager
import org.junit.Test

import static org.junit.Assert.*

import static extension com.plugback.persistence.DBExtension.*

class TestDBExtension {

	@Test(expected=IllegalArgumentException)
	def void testDBWhereQuery() {
		val db = new InMemoryEntityManager
		val tq = db.find(PojoForTest).where[x = "y" and oper = 2 or ox = true]
		val ps = (tq as FakeTypedQuery<?>).setParameters
		assertEquals(3, ps.size)
		assertEquals("p0 = y", ps.get(0))
		assertEquals("p1 = 2", ps.get(1))
		assertEquals("p3 = true", ps.get(2))
	}

	@Test
	def void testDBWhereQuery2() {
		val db = new InMemoryEntityManager
		val tq = db.find(PojoForTest).where[x = "y" and oper = 2]
		val ps = (tq as FakeTypedQuery<?>).setParameters
		assertEquals(2, ps.size)
		assertEquals("p0 = y", ps.get(0))
		assertEquals("p1 = 2", ps.get(1))
	}

}

class PojoForTest {

	@Property String x
	@Property Integer oper
	@Property Boolean ox

}
