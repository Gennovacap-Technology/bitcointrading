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
  'ok_btcusd_future_ticker_quarter'
]

class Server

  attr_reader :quit, :pid, :logfile

  def initialize(app)
    @pid = Pid.new(app)
    @log = Log.new(app)
  end

  def run!
    @pid.check
    daemonize
    @pid.write
    trap_signals
    @log.redirect_output

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

end
