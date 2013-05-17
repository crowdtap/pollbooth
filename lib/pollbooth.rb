require 'active_support/core_ext'
require 'bigben'

module PollBooth
  extend ActiveSupport::Concern

  included do
    class << self
      attr_accessor :poller
      attr_accessor :options
      attr_accessor :data_block
    end
  end

  module ClassMethods
    def configure(options={})
      self.options ||= {}
      self.options = self.options.merge(options)
    end

    def start
      raise "you must run configure before starting" if self.options.nil?
      raise "you must provide a load_data block before starting" if self.data_block.nil?

      self.stop
      self.poller = new(self.options)
    end

    def stop
      self.poller.stop if self.poller
    end

    def lookup(value)
      raise "Poller not started" unless self.poller.try(:started?)

      self.poller.lookup(value)
    end

    def data(&block)
      self.data_block = block
    end
  end

  def initialize(options)
    @ttl   = options[:ttl]   || 60
    @cache = options[:cache] ||= :on

    @lock = Mutex.new
    load_data # synchronous, blocking request so lookup always find something
    if cached?
      @timer = BigBen.new("PollBooth", @interval) { load_data }
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
    load_data unless cached?
    @lock.synchronize { @cached_data[value] }
  end

  def stop
    @timer.reset if cached?
    @started = false
  end

  def cached?
    @cache == :on
  end

  private

  def load_data
    data = self.class.data_block.call
    @lock.synchronize { @cached_data = data }
  end
end
