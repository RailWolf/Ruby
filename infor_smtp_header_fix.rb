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
seen = false

#Gather all recipients and the sender
emailarray = email.split(/\n/)
	emailarray.each do |c|
		if c =~ to
			recipients <<  c.gsub('To: ', '')
		elsif c =~ from
			sender = c.gsub('From: ', '')
		end	
	end

#Overwrite To: field and drop the duplicates
recstring = recipients.join(", ")
	commatized = emailarray.each_with_index do |c, i|
		if c =~ to
			if !seen
			  c = c.gsub!(to, "To: #{recstring}")
			  seen = true
			else
			  emailarray.delete_at(i)
			end
		end
	end
		
helodomain = sender.gsub(/(.*)@/, '')
message = commatized.join("\n")
smtp = Net::SMTP.new(relayhost, 25)
 smtp.start(helo: helodomain) do |smtp|
   smtp.send_message message,
       sender,
       [ recipients ]
 smtp.finish
end
