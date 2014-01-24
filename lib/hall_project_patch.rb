module RedmineHall
  module Patches
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          safe_attributes 'hall_auth_token'
        end
      end
    end
  end
end
