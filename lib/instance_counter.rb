# base on Oink::InstanceTypeCounter

module MongoDbLogger

  def self.extended_active_record?
    @oink_extended_active_record
  end

  def self.extended_active_record!
    @oink_extended_active_record = true
  end

  module InstanceCounter
    def self.included(klass)
      if Rails.logger && Rails.logger.respond_to?(:add_metadata)
        ActiveRecord::Base.send(:include, MongoDbLoggerInstanceCounterInstanceMethods)

        klass.class_eval do
          after_filter :report_instance_type_count
        end
      end
    end

    def before_report_active_record_count(instantiation_data)
    end

    private

    def report_instance_type_count
      report_hash = ActiveRecord::Base.instantiated_hash.merge("Total" => ActiveRecord::Base.total_objects_instantiated)
      Rails.add_metadata(:instance_counter => report_hash)
      ActiveRecord::Base.reset_instance_type_count
    end

  end

  module MongoDbLoggerInstanceCounterInstanceMethods

    def self.included(klass)
      klass.class_eval do

        @@instantiated = {}
        @@total = nil

        def self.reset_instance_type_count
          @@instantiated = {}
          @@total = nil
        end

        def self.instantiated_hash
          @@instantiated
        end

        def self.total_objects_instantiated
          @@total ||= @@instantiated.inject(0) { |i, j| i + j.last }
        end

        unless MongoDbLogger.extended_active_record?
          if instance_methods.include?("after_initialize")
            def after_initialize_with_oink
              after_initialize_without_oink
              increment_ar_count
            end

            alias_method_chain :after_initialize, :oink
          else
            def after_initialize
              increment_ar_count
            end
          end

          MongoDbLogger.extended_active_record!
        end

      end
    end

    def increment_ar_count
      @@instantiated[self.class.base_class.name] ||= 0
      @@instantiated[self.class.base_class.name] = @@instantiated[self.class.base_class.name] + 1
    end

  end
end