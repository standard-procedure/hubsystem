module Amygdala
  class AuthorisationChecker
    def check(sender, recipient)
      return :allowed if recipient.groups.empty?

      recipient_group_ids = recipient.groups.pluck(:id)

      sender.security_passes.each do |pass|
        if pass.capabilities.include?("message") && recipient_group_ids.include?(pass.group_id)
          return :allowed
        end
      end

      :denied
    end
  end
end
