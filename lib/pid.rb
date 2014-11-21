class Pid

  PID_PATH = 'tmp'

  attr_reader :pidfile

  def initialize(pidfile)
    @pidfile = File.expand_path("#{pidfile}.pid", PID_PATH)
  end

  def write
    begin
      File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) do |file|
        file.write("#{Process.pid}")
      end
      at_exit { File.delete(pidfile) if File.exists?(pidfile) }
    rescue Errno::EEXIST
      check
      retry
    end
  end

  def check
    case status(pidfile)
    when :running, :not_owned
      puts "A server is already running. Check #{pidfile}"
      exit(1)
    when :dead
      File.delete(pidfile)
    end
  end

  def status(pidfile)
    return :exited unless File.exists?(pidfile)
    pid = ::File.read(pidfile).to_i
    return :dead if pid == 0
    Process.kill(0, pid)
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end

end
