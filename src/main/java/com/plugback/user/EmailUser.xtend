package com.plugback.user

import com.plugback.active.comparable.Comparable
import com.plugback.active.properties.Property
import javax.persistence.Entity

@Entity
@Comparable
class EmailUser extends PasswordUser {

	@Property String name
	@Property String email

}
