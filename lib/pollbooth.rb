require 'active_support/core_ext'
require 'bigben'

module PollBooth
  class PollerNotFoundError < ::StandardError; end;

  extend ActiveSupport::Concern
  require 'pollbooth/poller'

  included do
    class << self
      attr_accessor :poller
      attr_accessor :ttl
      attr_accessor :cache_block
    end
  end

  module ClassMethods
    def start(cache_on=true)
      raise "you must provide cache block before starting" if self.cache_block.nil?

      self.stop
      self.poller = Poller.new(self, cache_on)
    end

    def stop
      self.poller.stop if self.poller
    end

    def lookup(value)
      raise PollBooth::PollerNotFoundError.new("Poller not started") unless self.poller.try(:started?)

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
