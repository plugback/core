package com.plugback.mail

import com.amazonaws.auth.AWSCredentials
import com.amazonaws.services.simpleemail.AWSJavaMailTransport
import java.util.Date
import java.util.Properties
import javax.inject.Inject
import javax.mail.Message
import javax.mail.MessagingException
import javax.mail.Session
import javax.mail.internet.AddressException
import javax.mail.internet.InternetAddress
import javax.mail.internet.MimeMessage
import com.plugback.active.interfaces.GenerateInterface

@GenerateInterface("MailSender")
class AmazonMailSender {

	@Inject
	AWSCredentials credentials

	override void sendMail(String to, String subject, String body, String from) {
		val props = new Properties
		props.setProperty("mail.transport.protocol", "aws");

		props.setProperty("mail.aws.user", credentials.AWSAccessKeyId)
		props.setProperty("mail.aws.password", credentials.AWSSecretKey)

		val session = Session.getInstance(props)

		try {
			val msg = new MimeMessage(session)
			msg.setFrom(new InternetAddress(from))
			msg.addRecipient(Message.RecipientType.TO, new InternetAddress(to))
			msg.setSubject(subject)
			msg.setSentDate(new Date)
			msg.setContent(body, "text/html")
			msg.saveChanges

			val t = new AWSJavaMailTransport(session, null)
			t.connect
			t.sendMessage(msg, null)

			t.close
		} catch (AddressException e) {
			println(
				'''Caught an AddressException, which means one 
						or more of your addresses are improperly formatted.''')
			e.printStackTrace
		} catch (MessagingException e) {
			println(
				'''Caught a MessagingException, which means that there was a 
						problem sending your message to Amazon's E-mail Service check the 
						stack trace for more information.''')
			e.printStackTrace
		}
	}

}
