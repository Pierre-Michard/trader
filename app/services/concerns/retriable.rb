module Retriable
  extend ActiveSupport::Concern

  def with_retries(nb_retries: 3)
    retried = 0
    begin 
      yield
    rescue => e
      Rails.logger.warn("#{caller[0][/`.*'/][1..-2]}: an #{e.class} exception occurred: #{e.message}")
      if retried < nb_retries
        sleep(0.3 * 2**retried)
        retried = retried + 1
        retry
      else
        raise
      end
    end
  end
end