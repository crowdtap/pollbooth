require 'active_support/core_ext'
require 'bigben'

class PollBooth
  class_attribute :poller
  class_attribute :options
  @@data = nil

  def self.configure(options={})
    self.options = options
  end

  def self.start
    raise "you must run configure before starting" if self.options.nil?
    raise "you must provide a load_data block before starting" if @@data.nil?

    self.stop
    self.poller = new(self.options)
  end

  def self.stop
    self.poller.stop if self.poller
  end

  def self.lookup(value)
    raise "Poller not started" unless self.poller.try(:started?)

    self.poller.lookup(value)
  end

  def self.data(&block)
    @@data = block
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
    @lock.synchronize { @data[value] }
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
    data = @@data.call
    @lock.synchronize { @data = data }
  end
end
