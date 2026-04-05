# frozen_string_literal: true

class HubSystem::BasicSecurityPass < HubSystem::SecurityPass
  has_attribute :from_date, :date
  has_attribute :until_date, :date

  def authorised?(*requests)
    date_valid? && allows?(*requests)
  end

  private

  def date_valid?
    return true if from_date.nil? && until_date.nil?
    return Date.current >= from_date if until_date.nil?
    return Date.current <= until_date if from_date.nil?
    Date.current.between?(from_date, until_date)
  end
end
