require 'active_support/core_ext'
require 'bigben'

module PollBooth
  extend ActiveSupport::Concern

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
      self.poller = new(cache_on)
    end

    def stop
      self.poller.stop if self.poller
    end

    def lookup(value)
      raise "Poller not started" unless self.poller.try(:started?)

      self.poller.lookup(value)
    end

    def cache(ttl, &block)
      self.cache_block = block
      self.ttl = ttl
    end
  end

  def initialize(cache_on)
    @cache_on = cache_on
    @ttl      = self.class.ttl.seconds
    @lock     = Mutex.new

    load_data # synchronous, blocking request so lookup always find something

    if @cache_on
      @timer = BigBen.new("PollBooth", @ttl) { load_data }
      @timer.start
    end
    @started = true
  end

  def started?
    @started == true
  end

  def load
    raise "load must be defined in a subclass"
  end

  def lookup(value)
    load_data unless @cache_on
    @lock.synchronize { @cached_data[value] }
  end

  def stop
    @timer.reset if @cache_on
    @started = false
  end

  private

  def load_data
    data = self.instance_eval(&self.class.cache_block)
    @lock.synchronize { @cached_data = data }
  end
end
