require 'faye/websocket'
require 'eventmachine'
require 'redis'
require 'json'

EM.run {
  CHANNELS = [
    'ok_btcusd_future_ticker_this_week',
    'ok_btcusd_future_ticker_next_week',
    'ok_btcusd_future_ticker_month',
    'ok_btcusd_future_ticker_quarter'
  ]

  ws = Faye::WebSocket::Client.new('wss://real.okcoin.com:10440/websocket/okcoinapi')
  redis = Redis.new

  ws.on :open do |event|
    puts "connection open"

    CHANNELS.each do |channel|
      ws.send(%Q[{"event":"addChannel","channel":"#{channel}"}])
    end
  end

  ws.on :message do |event|
    event_object = JSON.parse(event.data)
    event_object.each do |ev|
      redis.publish(ev['channel'], ev['data'].to_json)
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
