module PollBooth
  class PollBoothRailtie < ::Rails::Railtie
    initializer 'pollbooth' do
      ActionDispatch::Reloader.to_cleanup do
        PollBooth.pollers.each(&:stop)
      end
    end
  end
end
