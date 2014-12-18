require 'server'
class Collector < Server

  WS_URL = 'wss://real.okcoin.com:10440/websocket/okcoinapi'
  PING = 5 # seconds

  def self.run!
    Server.new('collector').run! do
      EM.run do
        puts "starting EventMachine at #{Time.now}"
        @ws = nil

        EM.add_timer(PING) do
          start_websocket if @ws.nil?
        end
      end
    end
  end

  private
  def self.start_websocket
    @ws = Faye::WebSocket::Client.new(WS_URL, nil, {ping: 5})
    redis = Redis.new

    @ws.on :open do |event|
      p [:open, Time.now]

      CHANNELS.each do |channel|
        @ws.send(%Q[{"event":"addChannel","channel":"#{channel}"}])
      end
    end

    @ws.on :message do |event|
      event_object = JSON.parse(event.data)
      event_object.each do |ev|
        redis.publish(ev['channel'], ev['data'].to_json)
      end
    end

    @ws.on :close do |event|
      p [:close, event.code, event.reason, Time.now]
      @ws = nil
    end
  end

end
