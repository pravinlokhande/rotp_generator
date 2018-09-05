#!/usr/bin/env ruby
# A ruby library for generating one time passwords (HOTP & TOTP) according to RFC 4226 and RFC 6238. https://github.com/mdp/rotp
# gem 'rotp', '~> 3.3', '>= 3.3.1'
# gem install rotp

require 'rotp'
require 'erb'

module ROTPService
  APP_NAME = "Avegen"

  TEMPLATES = {
    qr: %{
      https://chart.googleapis.com/chart?chs=200x200&chld=M|0&cht=qr&chl=%s
    }.strip,

    details: %{
:qr_code_url=> %s ,
:secret=> %s ,
:provisioning_url=> %s
    }.strip,

    usage: %{
Usage: %s [ new EMAIL | test SECRET CODE ]
Examples:
    # create new shared secret for hello@example.com
    ruby %s hello@example.com
    }.strip,
  }

  class QRCode
    def initialize(data) 
      @data = data
    end

    def to_s
      TEMPLATES[:qr] % [ERB::Util.url_encode(@data)]
    end
  end

  class Generator
    def initialize(secret, email, app_name = APP_NAME)
      @secret, @email, @app_name = secret, email, app_name
      # generate provisioning uri
      @uri = ROTP::TOTP.new(@secret, issuer: @app_name).provisioning_uri(@email)
    end

    def to_s
      TEMPLATES[:details] % [QRCode.new(@uri), @secret, @uri]
    end
  end

  def self.print_usage(app)
    $stderr.puts TEMPLATES[:usage] % ([app]  * 3)
    exit -1
  end

  def self.generate_qr_code(app, args)
    print_usage(app) unless args.length == 1
    # get email from args
    email = args.shift
    # generate shared secret
    secret = ROTP::Base32.random_base32
    # generate and print result
    puts Generator.new(secret, email)
  end
end

# run app
ROTPService.generate_qr_code($0, ARGV) if __FILE__ == $0
