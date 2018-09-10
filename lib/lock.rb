require 'remote_lock'

class Lock
  module ClassMethods
    def acquire(name)
      mutex.synchronize(fixed_name(name)) do
        yield if block_given?
      end
    end

    def acquired?(name)
      mutex.acquired?(fixed_name(name))
    end

    private

    def fixed_name(name)
      name.gsub(/\s+/, '-')
    end

    def mutex
      @mutex ||= begin
        redis_adapter = RemoteLock::Adapters::Redis.new($redis)
        RemoteLock.new(redis_adapter)
      end
    end

  end
  extend ClassMethods
end