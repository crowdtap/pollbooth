class PollBooth::Poller
  def initialize(klass, cache_on)
    @klass    = klass
    @instance = klass.new
    @cache_on = cache_on
    @ttl      = @klass.ttl.seconds
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
    data = @instance.instance_eval(&@klass.cache_block)
    @lock.synchronize { @cached_data = data.with_indifferent_access }
  end
end
