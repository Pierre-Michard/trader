module Retriable
  extend ActiveSupport::Concern

  def with_retries(nb_retries: 3)
    yield
  rescue => e
    Rails.logger.warn("#{caller[0][/`.*'/][1..-2]}: an #{e.class} exception occurred: #{e.message}")
    if nb_retries > 0
      sleep(0.2)
      nb_retries = nb_retries - 1
      retry
    else
      raise
    end
  end
end