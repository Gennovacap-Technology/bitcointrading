class Log

  LOG_PATH = 'log'

  attr_reader :logfile

  def initialize(logfile)
    @logfile = File.expand_path("#{logfile}.log", LOG_PATH)
  end

  def redirect_output
    FileUtils.mkdir_p(File.dirname(logfile), :mode => 0755)
    FileUtils.touch logfile
    File.chmod(0644, logfile)
    $stderr.reopen(logfile, 'a')
    $stdout.reopen($stderr)
    $stdout.sync = $stderr.sync = true
  end

  def self.write(message)
    puts "[#{Process.pid}] [#{Time.now}] #{message}"
  end

end
