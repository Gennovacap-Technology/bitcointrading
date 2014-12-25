require 'faye/websocket'
require 'eventmachine'
require 'redis'
require 'json'
require 'fileutils'

require 'pid'
require 'log'

CHANNELS = [
  'ok_btcusd_future_ticker_this_week',
  'ok_btcusd_future_ticker_next_week',
  'ok_btcusd_future_ticker_month',
  'ok_btcusd_future_ticker_quarter',
  'ok_btcusd_ticker'
]

class Server

  attr_reader :quit, :pid, :logfile

  def initialize(app)
    @pid = Pid.new(app)
    @log = Log.new(app)
  end

  def run!
    @log.redirect_output
    @pid.check
    daemonize
    @pid.write
    trap_signals

    yield if block_given?

    Log::write("Finished")
  end

  def daemonize
    exit if fork
    Process.setsid
    exit if fork
    Dir.chdir "/"
  end

  def trap_signals
    trap(:QUIT) { @quit = true }
  end

  def self.restart_process(process)
    path = File.expand_path(File.dirname(__FILE__))
    new_path = path.split('/')[0..-2].join('/')
    pidfile = File.join(new_path, 'tmp', "#{process}.pid")
    Dir.chdir(new_path) do
      File.delete(pidfile) if File.exists?(pidfile)
      `ruby -Ilib bin/#{process}`
    end
    Process.exit!(true)
  end

end
