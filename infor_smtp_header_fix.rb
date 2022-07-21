#!/opt/bin/ruby
#RFC 5322 fix for Infor OS ION Alert emails. 
#Infor incorrectly adds multiple To: lines in the header instead of using a single To: line with a comma-delimited list. This fixes it.
#2022 Brandon Calhoun
require 'net/smtp'

#Read STDIN from postfix
email = STDIN.read
relayhost = "smtp-relay.gmail.com"
recipients = []
newmail = []
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

#Form a new array with a fixed up To: field
recstring = recipients.join(", ")
emailarray.each_with_index do |c, i|
	if c !~ to
		newmail << c
	elsif c =~ to
		if	!seen
			c = c.gsub!(to, "To: #{recstring}")
			seen = true
			newmail << c
		end
	end
end
		
helodomain = sender.gsub(/(.*)@/, '')
message = newmail.join("\n")

smtp = Net::SMTP.new(relayhost, 25)
 smtp.start(helo: helodomain) do |smtp|
   smtp.send_message message,
       sender,
       [ recipients ]
 smtp.finish
end
