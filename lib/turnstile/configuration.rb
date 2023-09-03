# frozen_string_literal: true

module Turnstile
  # This class enables detailed configuration of the turnstile services.
  #
  # By calling
  #
  #   Turnstile.configuration # => instance of Turnstile::Configuration
  #
  # or
  #   Turnstile.configure do |config|
  #     config # => instance of Turnstile::Configuration
  #   end
  #
  # you are able to perform configuration updates.
  #
  # Your are able to customize all attributes listed below. All values have
  # sensitive default and will very likely not need to be changed.
  #
  # Please note that the site and secret key for the Turnstile API Access
  # have no useful default value. The keys may be set via the Shell enviroment
  # or using this configuration. Settings within this configuration always take
  # precedence.
  #
  # Setting the keys with this Configuration
  #
  #   Turnstile.configure do |config|
  #     config.site_key  = '1x00000000000000000000AA'
  #     config.secret_key = '1x0000000000000000000000000000000AA'
  #   end
  #
  class Configuration
    DEFAULTS = {
      'server_url' => 'https://challenges.cloudflare.com/turnstile/v0/api.js',
      'verify_url' => 'https://challenges.cloudflare.com/turnstile/v0/siteverify'
    }.freeze

    attr_accessor :default_env, :skip_verify_env, :secret_key, :site_key, :proxy, :handle_timeouts_gracefully, :hostname
    attr_writer :api_server_url, :verify_url

    def initialize # :nodoc:
      @default_env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || (Rails.env if defined? Rails.env)
      @skip_verify_env = %w[test cucumber]
      @handle_timeouts_gracefully = true

      @secret_key = ENV.fetch('TURNSTILE_SECRET_KEY', nil)
      @site_key = ENV.fetch('TURNSTILE_SITE_KEY', nil)
      @verify_url = nil
      @api_server_url = nil
    end

    def secret_key!
      secret_key || raise(TurnstileError, "No secret key specified.")
    end

    def site_key!
      site_key || raise(TurnstileError, "No site key specified.")
    end

    def api_server_url
      @api_server_url || DEFAULTS.fetch('server_url')
    end

    def verify_url
      @verify_url || DEFAULTS.fetch('verify_url')
    end
  end
end
