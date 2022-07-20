#!/opt/bin/ruby

#RFC 5322 fix for Infor OS ION Alert emails. 
#Infor incorrectly adds multiple To: lines in the header instead of using a single To: line with a comma-delimited list. This fixes it.
#2022 Brandon "RailWolf" Calhoun

require 'net/smtp'

email = STDIN.read
recipients = []
sender = ""
emailarray = email.split(/\n/)
	emailarray.each do |c|
		if c =~ /^To: (.*)/
			recipients <<  c.gsub('To: ', '')
		end
		if c =~ /^From: (.*)/
			sender = c.gsub('From: ', '')
		end	
	end

recstring = recipients.join(", ")

build_to_field = emailarray.each do |c|
	if c =~ /^To: (.*)/
		c = c.gsub!(/^To: (.*)$/, "To: #{recstring}")
	end
end
		
helodomain = sender.gsub(/(.*)@/, "")

#So basically we've created multiple identical [correctly formated] To: lines that .uniq will drop.
#Need to make sure this doesn't trample on anything else, maybe a pattern match.
output = build_to_field.uniq.join("\n")

smtp = Net::SMTP.new('smtp-relay.gmail.com', 25)

 smtp.start(helo: helodomain) do |smtp|
   smtp.send_message output,
       sender,
       [ recipients ]
   smtp.finish
end
