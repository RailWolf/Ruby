#!/opt/bin/ruby
#RFC 5322 fix for Infor OS ION Alert emails. 
#Infor incorrectly adds multiple To: lines in the header instead of using a single To: line with a comma-delimited list. This fixes it.
#2022 Brandon Calhoun
require 'net/smtp'

#Read STDIN from postfix
email = STDIN.read
relayhost = "smtp-relay.gmail.com"
recipients = []
newemail = []
sender = ""
to = /^To: (.*)/
from = /^From: (.*)/
seen = false

#Gather all recipients and the sender
email = email.split(/\n/)
email.each do |c|
	if c =~ to
		recipients <<  c.gsub('To: ', '')
	elsif c =~ from
		sender = c.gsub('From: ', '')
	end	
end

#Form a new array with a fixed up To: field
recstring = recipients.join(", ")
email.each_with_index do |c, i|
	if c !~ to
		newemail << c
	elsif c =~ to
		if	!seen
			c = c.gsub!(to, "To: #{recstring}")
			seen = true
			newemail << c
		end
	end
end
		
helodomain = sender.gsub(/(.*)@/, '')
message = newemail.join("\n")

begin
smtp = Net::SMTP.new(relayhost, 25)
 smtp.start(helo: helodomain) do |smtp|
   smtp.send_message message,
       sender,
       [ recipients ]
 smtp.finish
 rescue Net::OpenTimeout
 retry
end
end
