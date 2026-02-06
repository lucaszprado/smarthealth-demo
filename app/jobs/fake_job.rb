class FakeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info("[FakeJob] args=#{args.inspect}")
    puts "I'm starting the fake job"
    sleep 3
    puts "OK I'm done now"
  end
end
