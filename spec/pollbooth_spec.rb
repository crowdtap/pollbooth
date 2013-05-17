require 'spec_helper'

describe PollBooth do
  subject do
    define_constant :TestPoller, PollBooth do
      def load
        @counter ||= 0
        data = { :counter => @counter }
        @counter += 1
        data
      end
    end
  end

  before { subject.configure(options) }

  context "when caching it turned off" do
    let(:options) { { :cache => :off } }

    it "reloads data every lookup" do
      subject.start

      20.times { subject.lookup(:counter) }

      subject.lookup(:counter).should == 21
    end
  end
  context "when caching it turned on" do
    let(:options) { { :ttl => 1, :cache => :on } }

    context "when a poller has been started" do
      before { subject.start }
      after  { subject.stop }

      it "updates the cache asynchronously" do
        subject.lookup(:counter).should == 0

        sleep 2

        subject.lookup(:counter).should >= 1
      end

      context "when the poller is started again" do
        it "stops the current poller creates a new one" do
          poller = subject.poller

          subject.start

          poller.started?.should == false
          subject.poller.should_not == poller
          subject.poller.started?.should == true
        end
      end

      context "a another poller exists and has been started" do
        let(:another_poller) do
          define_constant :AnotherTestPoller, PollBooth do
            def load
              @counter ||= 0
              data = { :counter => @counter }
              @counter += 10
              data
            end
          end
        end
        before { another_poller.configure(options) }
        before { another_poller.start }
        after  { another_poller.stop }

        it "can run two pollers at the same timeat the same time" do
          subject.lookup(:counter).should == 0
          another_poller.lookup(:counter).should == 0

          sleep 2

          another_poller.lookup(:counter).should >= 9
          subject.lookup(:counter).should >= 1
        end

        it "returns nil if the lookup value doesn't exist" do
          subject.lookup(:doesnotexist).should == nil
        end
      end
    end

    context "when a poller has not been started" do
      it "raises an exception" do
        expect {
          subject.lookup(:counter)
        }.to raise_error(RuntimeError)
      end
    end
  end
end
