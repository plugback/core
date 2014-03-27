package com.plugback.user

import com.plugback.active.comparable.Comparable
import javax.persistence.Entity
import org.apache.shiro.crypto.hash.Sha512Hash

@Entity
@Comparable
class PasswordUser extends AppUser {
	
	private var String hashedPassword;
	
	def PasswordUser setHashedPassword(String password){
		this.hashedPassword = hash(password).toHex
		return this
	}
	
	def matchesPassword(String password){
		return hash(password).toHex == hashedPassword
	}
	
	def hash(String password) {
		new Sha512Hash(id + password)
	}
	
}