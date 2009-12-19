# base on Oink::MemoryUsageLogger
#
# It stores how much megabytes process have after action has end

module MongoDbLogger
  module MemoryUsage
    def self.included(klass)
      klass.class_eval do
        after_filter :log_memory_usage
      end if Rails.logger && Rails.logger.respond_to?(:add_metadata)
    end

    private
      def get_memory_usage
          `ps -o rss= -p #{$$}`.to_i/1024
      end

      def log_memory_usage
          memory_usage = get_memory_usage
          Rails.logger.add_metadata(:memory_usage => memory_usage,
                                    :pid => $$)
      end
  end
end