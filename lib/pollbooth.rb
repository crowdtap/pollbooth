require 'active_support/core_ext'
require 'bigben'

class PollBooth
  class_attribute :poller

  def self.start(options={})
    self.stop
    self.poller = new(options)
  end

  def self.stop
    self.poller.stop if self.poller
  end

  def self.lookup(value)
    raise "Poller not started" unless self.poller.try(:started?)

    self.poller.lookup(value)
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
    @timer.reset
    @started = false
  end

  def cached?
    @cache == :on
  end

  private

  def load_data
    data = self.load
    @lock.synchronize { @data = data }
  end
end
