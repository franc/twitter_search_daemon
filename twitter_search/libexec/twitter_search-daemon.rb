# Generated cron daemon

# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
  # Trap signals with blocks or procs
  # config.trap( 'INT' ) do
  #   # do something clever
  # end
  # config.trap( 'TERM', Proc.new { puts 'Going down' } )
end

# Configuration documentation available at http://rufus.rubyforge.org/rufus-scheduler/
# An instance of the scheduler is available through
# DaemonKit::Cron.scheduler

# To make use of the EventMachine-powered scheduler, uncomment the
# line below *before* adding any schedules.
DaemonKit::EM.run

# Some samples to get you going:

# Will call #regenerate_monthly_report in 3 days from starting up
#DaemonKit::Cron.scheduler.in("3d") do
#  regenerate_monthly_report()
#end
#
#DaemonKit::Cron.scheduler.every "10m10s" do
#  check_score(favourite_team) # every 10 minutes and 10 seconds
#end
#
#DaemonKit::Cron.scheduler.cron "0 22 * * 1-5" do
#  DaemonKit.logger.info "activating security system..."
#  activate_security_system()
#end
#
# Example error handling (NOTE: all exceptions in scheduled tasks are logged)
#DaemonKit::Cron.handle_exception do |job, exception|
#  DaemonKit.logger.error "Caught exception in job #{job.job_id}: '#{exception}'"
#end

DaemonKit::Cron.scheduler.every("5s") do
  log "Start"
  attitudes = get_attitudes()
  attitudes.each do |attitude|
    search_twitter_for attitude
  end

  log "Scheduled task completed at #{Time.now}"
end

def search_twitter_for(attitude)

  log attitude.inspect
  http = EventMachine::HttpRequest.new('http://search.twitter.com/search.json').get :query => {
    'q' => attitude[:rules]#,
    #'q' => URI::encode(attitude[:rules])#,
    #'geocode' => "-33.925278, 18.423889,20m"
  }

  http.errback { p 'Uh oh'; EM.stop }
  http.callback {
    log http.response_header.status
    log http.response_header
    log http.response
    log JSON.parse(URI::decode(http.response))

    results = JSON.parse(URI::decode(http.response))['results']
    log "results:"
    log results.map{|a| a['text']}
    EM.stop
  }
end

def get_attitudes
  [
    {
      name: 'grattitude',
      rules: 'grateful OR gratitude OR thankful'
    }
  ]
end

def log(msg, type = :debug)
  #DaemonKit.logger.debug(msg) if type == :debug
  ap msg
end

# Run our 'cron' dameon, suspending the current thread
DaemonKit::Cron.run
