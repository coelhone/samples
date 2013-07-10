class SelfPipeSample
  HANDLED_SIGNALS = [ :TERM, :USR1, :USR2 ]

  def initialize
    @selfpipe_reader, @selfpipe_writer = create_pipe
    @signal_queue  = []
  end

  def start
    register_signals
    signals_listener
  end

  ########################### OVERRIDABLE ###############################
  # Handle an INT signal
  def handle_term
    puts "SIGTERM received"
  end

  # Handle a USR1 signal
  def handle_usr1
    puts "SIGUSR1 received"
  end

  # Handle a USR2 signal
  def handle_usr2
    puts "SIGUSR2 received"
  end

  ############################# PRIVATE #################################
  private

  # not entirely necessary if IO.select is only consuming the signals from IO
  def create_pipe
    IO.pipe
  end

  def register_signals
    HANDLED_SIGNALS.each do |signal|
	trap(signal) do 
           @signal_queue << signal
           notice_signal 
        end if Signal.list.include? signal.to_s
    end
  end

  def notice_signal
    @selfpipe_writer.write_nonblock('.')
  rescue Errno::EAGAIN
    # Ignore writes that would block
  rescue Errno::EINT
    # Retry if another signal arrived while writing
    retry
  end

  # select should listen to more file descriptors if needed, also a block
  # of code should be created in order to process those signals
  def signals_listener
    begin
      loop do
        io = IO.select([@selfpipe_reader])

        if io[0].include?(@selfpipe_reader)
          @selfpipe_reader.read_nonblock(1)
 
          while sig = @signal_queue.pop
            signal_handling sig
          end
        end
      end
    rescue Exception => ex
      puts ex.inspect
      puts ex.backtrace
    end
  end

  def signal_handling sig
    case sig
      when :TERM
        handle_term
      when :USR1
        handle_usr1
      when :USR2
        handle_usr2
      end
  end
end
