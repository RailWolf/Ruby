#!/opt/bin/ruby
#RFC 5322 fix for Infor OS ION Alert emails. 
#Infor incorrectly adds multiple To: lines in the header instead of using a single To: line with a comma-delimited list. This fixes it.
#2022 Brandon "RailWolf" Calhoun
require 'net/smtp'

#Read STDIN from postfix
email = STDIN.read
relayhost = "smtp-relay.gmail.com"
recipients = []
sender = ""
to = /^To: (.*)/
from = /^From: (.*)/

#Gather all recipients and the sender
emailarray = email.split(/\n/)
	emailarray.each do |c|
		if c =~ to
			recipients <<  c.gsub('To: ', '')
		elsif c =~ from
			sender = c.gsub('From: ', '')
		end	
	end

#Note: /^Content\-Type: application\/octet-stream(.*)/
#Overwrite To: fields
recstring = recipients.join(", ")
	commatized = emailarray.each do |c|
		if c =~ to
			  c = c.gsub!(to, "To: #{recstring}")
		end
	end
		
helodomain = sender.gsub(/(.*)@/, '')

#There are now duplicate To: lines that .uniq will take care of.
#Need to make sure this doesn't trample on anything else, maybe a pattern match.
message = commatized.uniq.join("\n")
smtp = Net::SMTP.new(relayhost, 25)
 smtp.start(helo: helodomain) do |smtp|
   smtp.send_message message,
       sender,
       [ recipients ]
 smtp.finish
end
