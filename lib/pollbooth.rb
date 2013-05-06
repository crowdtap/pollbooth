require 'active_support/core_ext'
require 'bigben'

class PollBooth
  class_attribute :poller

  def self.start(interval=60)
    self.poller = new(interval)
  end

  def self.stop
    self.poller.stop if self.poller
  end

  def self.lookup(value)
    raise "Poller not started" unless self.poller.try(:started?)

    self.poller.lookup(value)
  end

  def initialize(interval)
    @interval = interval
    @lock = Mutex.new

    load_data # synchronous, blocking request so lookup always find something
    @timer = BigBen.new("PollBooth", @interval) { load_data }
    @timer.start
    @started = true
  end

  def started?
    @started == true
  end

  def load
    raise "load must be defined in a subclass"
  end

  def lookup(value)
    @lock.synchronize { @data[value] }
  end

  def stop
    @timer.reset
  end

  private

  def load_data
    data = self.load
    @lock.synchronize { @data = data }
  end
end
