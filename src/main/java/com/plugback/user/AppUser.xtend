package com.plugback.user

import com.plugback.active.comparable.Comparable
import com.plugback.active.properties.Property
import java.util.Date
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id
import javax.persistence.Temporal
import javax.persistence.TemporalType

@Entity
@Comparable
class AppUser {

	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	@Property var Long id;

	@Temporal(TemporalType.TIMESTAMP)
	@Property Date lastTimeUpdated

	new() {
		creationDate = new Date();
		lastTimeUpdated = creationDate;
	}

	@Temporal(TemporalType.TIMESTAMP)
	@Property Date creationDate;

}
