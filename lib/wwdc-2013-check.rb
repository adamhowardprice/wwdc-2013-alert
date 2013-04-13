#!/usr/bin/env ruby
# wwdc-2013-check.rb by Adam Price, 2013

require 'rubygems'
require 'twilio-ruby'
require 'pony'
require 'net/https'
require 'uri'

# Constants
SHOULD_NOTIFY = true
IS_TEST = false
MESSAGE_SUBJECT = IS_TEST ? 'WWDC 2013 TEST NOTIFICATION' : 'WWDC 2013 ALERT UPDATE'
MESSAGE_BODY = IS_TEST ? 'THIS IS ONLY A TEST' : 'SITE HAS UPDATED! Go see: https://developer.apple.com/wwdc/'
EMAILS_TO_NOTIFY = [ENV['SENDGRID_TO_EMAIL_1'], ENV['SENDGRID_TO_EMAIL_2'], ENV['SENDGRID_TO_EMAIL3'], ENV['SENDGRID_TO_EMAIL_4'], ENV['SENDGRID_TO_EMAIL_5']]
NUMBERS_TO_NOTIFY = [ENV['TWILIO_TO_NUMBER'], ENV['TWILIO_TO_NUMBER2'], ENV['TWILIO_TO_NUMBER3'], ENV['TWILIO_TO_NUMBER4']]

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
			email_people
    		text_people
    	else
    		puts MESSAGE_BODY
    	end
    end

    ##################################################
    # EMAIL
    def email_people
		Pony.mail({
		  :to => EMAILS_TO_NOTIFY,
		  :from => "WWDC 2013 Alert! <#{ENV['SENDGRID_FROM_EMAIL']}>",
		  :subject => "#{MESSAGE_SUBJECT}",
		  :body => "#{MESSAGE_BODY}",
		  :via => :smtp,
		  :via_options => {
		    :address              => 'smtp.sendgrid.com',
		    :port                 => '587',
		    :enable_starttls_auto => false,
		    :domain               => "heroku.com",
		    :user_name            => ENV['SENDGRID_USERNAME'],
		    :password             => ENV['SENDGRID_PASSWORD'],
		    :authentication       => :plain # :plain, :login, :cram_md5, no auth by default
		  }
		})

		puts "Emailed: " + MESSAGE_BODY
    end

    ##################################################
    # TEXT
    def text_people
    	account_sid = ENV['TWILIO_ACCOUNT_SID']
		auth_token = ENV['TWILIO_AUTH_TOKEN']
		client = Twilio::REST::Client.new(account_sid, auth_token)
		account = client.account

    	NUMBERS_TO_NOTIFY.each do |number|
			message = account.sms.messages.create({:from => ENV['TWILIO_TRIAL_NUMBER'], :to => number, :body => MESSAGE_BODY})
    	end
    end
end

UpdateChecker.new.run