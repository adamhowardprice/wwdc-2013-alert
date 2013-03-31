#!/usr/bin/env ruby
# wwdc-2013-check.rb by Adam Price, 2013

require 'rubygems'
require 'twilio-ruby'
require 'net/https'
require 'uri'

# Constants
SHOULD_NOTIFY = false
MESSAGE_SUBJECT = "WWDC 2013 ALERT UPDATE"
MESSAGE_BODY = "SITE HAS UPDATED! Go see: https://developer.apple.com/wwdc/"

class UpdateChecker
	# Actions
	##################################################
    # Action: run
	def run
		case ARGV[0].to_s
		when "test"
			test
		else
			check
		end	
	end

	##################################################
    # Action: test
    def test
    	puts "No tests currently implemented"
    end
    
    ##################################################
    # Action: check
    def check
    	site_source = get_html
    	abort("Failed to get response") if site_source == ""
    	abort("This is still the 2012 WWDC site") if !( is_site_updated? site_source )
    	
    	notify_me
    end	

	##################################################
	# Private Functions    

    ##################################################
    # Step 1: Get the site if possible, otherwise just abort
    def get_html
		uri = URI.parse("https://developer.apple.com/wwdc/")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		request = Net::HTTP::Get.new(uri.request_uri)
		begin
		  	response = http.request(request)
		rescue Exception => e
		  	puts "Exception: " + e
		end

		if !response || response.body.empty? || response.code !~ /2|3\d{2}/
			return ""
		end

		return response.body
    end

    ##################################################
	# Step 2: Check if it includes the phrase: 
	# "WWDC 2012. June 11-15 in San Francisco. It's the week we've all been waiting for."
    def is_site_updated? site_string
		$last_year_string = "WWDC 2012. June 11-15 in San Francisco. It\'s the week we\'ve all been waiting for."
		return !( site_string.include? $last_year_string )
    end

    ##################################################
    # Step 3: If the site no longer includes the phrase, notify me!
    def notify_me
    	if SHOULD_NOTIFY
			#email_me
    		text_me
    	else
    		puts MESSAGE_BODY
    	end
    end

    ##################################################
    # EMAIL
    def email_me
		Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_PEER)
		smtp_addr = "smtp.gmail.com"
		domain = "gmail.com"
		sender = "wwdc2013alert@gmail.com"
		password = "notmacworld"
		recipients = ["adamhowardprice@gmail.com", "adamprice@spotify.com"]
    	message = <<-END_OF_MESSAGE
From: WWDC 2013 Alert <#{sender}>
To: Adam Price <#{recipients.join(', ')}>
Subject: #{MESSAGE_SUBJECT}

#{MESSAGE_BODY}
END_OF_MESSAGE
		 
		# smtp.enable_starttls
		Net::SMTP.start(smtp_addr, 587, domain, sender, password, :login) do |smtp|
		    smtp.send_message message, sender, recipients
		end

		puts "Emailed: " + message
    end

    ##################################################
    # TEXT
    def text_me
		account_sid = 'AC7aa58730695bda08042276d28e4621aa'
		auth_token = '0cf8597186de73c5421d6a214d73f450'

		client = Twilio::REST::Client.new(account_sid, auth_token)
		account = client.account
		message = account.sms.messages.create({:from => '+19177467795', :to => '+14052052965', 
			:body => MESSAGE_BODY})
    end
end

UpdateChecker.new.run