# frozen_string_literal: true

module Turnstile
  module Adapters
    module ControllerMethods
      private

      # Your private API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def verify_turnstile(options = {})
        options = { model: options } unless options.is_a? Hash
        return true if Turnstile.skip_env?(options[:env])

        model = options[:model]
        attribute = options.fetch(:attribute, :base)
        turnstile_response = options[:response] || turnstile_response_token(options[:action])

        begin
          verified = if Turnstile.invalid_response?(turnstile_response)
            false
          else
            unless options[:skip_remote_ip]
              remoteip =
                (request.respond_to?(:headers) &&
                  request.headers.respond_to?(:[]) &&
                  request.headers['CF-Connecting-IP']) ||
                (request.respond_to?(:remote_ip) && request.remote_ip)
              options = options.merge(remote_ip: remoteip.to_s) if remoteip
            end

            Turnstile.verify_via_api_call(turnstile_response, options)
          end

          if verified
            flash.delete(:turnstile_error) if turnstile_flash_supported? && !model
            true
          else
            turnstile_error(
              model,
              attribute,
              options.fetch(:message) { Turnstile::Helpers.to_error_message(:verification_failed) }
            )
            false
          end
        rescue Timeout::Error
          if Turnstile.configuration.handle_timeouts_gracefully
            turnstile_error(
              model,
              attribute,
              options.fetch(:message) { Turnstile::Helpers.to_error_message(:turnstile_unreachable) }
            )
            false
          else
            raise TurnstileError, 'Turnstile unreachable.'
          end
        rescue StandardError => e
          raise TurnstileError, e.message, e.backtrace
        end
      end

      def verify_turnstile!(options = {})
        verify_turnstile(options) || raise(VerifyError)
      end

      def turnstile_error(model, attribute, message)
        if model
          model.errors.add(attribute, message)
        elsif turnstile_flash_supported?
          flash[:turnstile_error] = message
        end
      end

      def turnstile_flash_supported?
        request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
      end

      # Extracts response token from params. params['cf-turnstile-response'] should either be a
      # string or a hash with the action name(s) as keys. If it is a hash, then `action` is used as
      # the key.
      # @return [String] A response token if one was passed in the params; otherwise, `''`
      def turnstile_response_token(action = nil)
        response_param = params['cf-turnstile-response']
        if response_param&.respond_to?(:to_h) # Includes ActionController::Parameters
          response_param[action].to_s
        else
          response_param.to_s
        end
      end
    end
  end
end
