# frozen_string_literal: true

module Turnstile
  module Adapters
    module ViewMethods
      def turnstile_tags(options = {})
        ::Turnstile::Helpers.turnstile(options)
      end
    end
  end
end
