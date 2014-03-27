package com.plugback.mail

import com.amazonaws.auth.AWSCredentials
import com.google.inject.AbstractModule

class MailModule extends AbstractModule{
	
	AWSCredentials aws
	
	override protected configure() {
		if(aws != null){
			bind(AWSCredentials).toInstance(aws)
			bind(MailSender).to(AmazonMailSender)
		}
	}
	
	def addAwsMailSupport(String accessKey, String secretKey){
		aws = new AwsCredentialImpl(accessKey, secretKey)
		return this
	}
	
}

@Data
class AwsCredentialImpl implements AWSCredentials{
	
	String accessKey
	String secretKey
	
	override getAWSAccessKeyId() {
		return accessKey
	}
	
	override getAWSSecretKey() {
		return secretKey
	}
	
}