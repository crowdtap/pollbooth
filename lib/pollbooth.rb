require 'active_support'
require 'active_support/core_ext'
require 'bigben'

module PollBooth
  extend ActiveSupport::Concern

  require 'pollbooth/poller'
  require 'pollbooth/railtie' if defined?(Rails)

  mattr_accessor :pollers

  included do
    class << self
      attr_accessor :poller
      attr_accessor :ttl
      attr_accessor :cache_block

      @@pollbooth_mutex = Mutex.new
    end
  end

  module ClassMethods
    def start(cache_on=true)
      raise "you must provide cache block before starting" if self.cache_block.nil?

      self.class_variable_get(:@@pollbooth_mutex).synchronize do
        self.stop
        self.poller = Poller.new(self, cache_on)
      end

      PollBooth.pollers ||= []
      PollBooth.pollers << self.poller
    end

    def stop
      self.poller.stop if self.poller
    end

    def lookup(value)
     self.start unless self.poller.try(:started?)

     self.poller.lookup(value)
    end

    def cache(ttl, &block)
      self.cache_block = block
      self.ttl = ttl
    end

    def started?
      self.poller.try(:started?) || false
    end
  end
end
