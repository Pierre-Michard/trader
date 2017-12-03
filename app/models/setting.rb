# RailsSettings Model
class Setting < RailsSettings::Base
  source Rails.root.join("config/app.yml")
  namespace Rails.env

  def self.counter_orders_service
    "#{self.reference_service.capitalize}Service".constantize.instance
  end
end
