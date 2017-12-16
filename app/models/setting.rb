# RailsSettings Model
class Setting < RailsSettings::Base
  source Rails.root.join("config/app.yml")
  namespace Rails.env

  def []=(var_name, value)
    super
    if var_name == 'active' && value == false
      Resque.redis.del('queue:trader_production_trader')
      PaymiumService.instance.cancel_all_orders
    end
  end

  def self.counter_orders_service
    "#{self.reference_service.capitalize}Service".constantize.instance
  end
end
