#!/opt/bin/ruby
#RFC 5322 fix for Infor OS ION Alert emails. 
#Infor incorrectly adds multiple To: lines in the header instead of using a single To: line with a comma-delimited list. This fixes it.
#2022 Brandon "RailWolf" Calhoun
require 'net/smtp'

email = STDIN.read
relayhost = "smtp-relay.gmail.com"
recipients = []
sender = ""

emailarray = email.split(/\n/)
	emailarray.each do |c|
		if c =~ /^To: (.*)/
			recipients <<  c.gsub('To: ', '')
		elsif c =~ /^From: (.*)/
			sender = c.gsub('From: ', '')
		end	
	end

recstring = recipients.join(", ")
	commatized = emailarray.each do |c|
		if c =~ /^To: (.*)/
			c = c.gsub!(/^To: (.*)$/, "To: #{recstring}")
		end
	end
		
helodomain = sender.gsub(/(.*)@/, "")

#So there are now duplicate To: lines that .uniq will take care of.
#Need to make sure this doesn't trample on anything else, maybe a pattern match.
output = commatized.uniq.join("\n")

smtp = Net::SMTP.new(relayhost, 25)
 smtp.start(helo: helodomain) do |smtp|
   smtp.send_message output,
       sender,
       [ recipients ]
 smtp.finish
end
