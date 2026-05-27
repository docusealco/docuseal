require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class AuthenticationGenerator < Base
      def initialize(args, *options)
        args.replace(['User'])
        super
      end

      def create_user_spec
        template 'user_spec.rb', target_path('models', 'user_spec.rb')
      end

      hook_for :fixture_replacement

      def create_fixture_file
        return if options[:fixture_replacement]

        template 'users.yml', target_path('fixtures', 'users.yml')
      end
    end
  end
end
