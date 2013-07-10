class SelfPipeSample
  HANDLED_SIGNALS = [ :TERM, :USR1, :USR2 ]
  OTHER_PROCESSES = [ :HUP ] #T

  def initialize
    @selfpipe_reader, @selfpipe_writer = create_pipe
    @signal_queue  = []
    @process_reader, @process_writer = create_pipe #T
    puts Process.pid
  end

  def start
    register_signals
    register_other_processes
    signals_listener
  end

  ########################### OVERRIDABLE ###############################
  # Handle an INT signal
  def handle_term
    puts "SIGTERM received"
#    raise "not implemented #{__method__}"
  end

  # Handle a USR1 signal
  def handle_usr1
    puts "SIGUSR1 received"
#    raise "not implemented #{__method__}"
  end

  # Handle a USR2 signal
  def handle_usr2
    puts "SIGUSR2 received"
#    raise "not implemented #{__method__}"
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
           puts "TRAPING SIGNAL"
           @signal_queue << signal
           notice_signal 
        end if Signal.list.include? signal.to_s
    end
  end

  #T
  def register_other_processes
    OTHER_PROCESSES.each do |signal|
	trap(signal) do 
           puts "TRAPING PROCESS"
           @process_writer.write_nonblock('.')
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

  def signals_listener
    begin
      loop do

sleep 5

        io = IO.select([@selfpipe_reader] + [@process_reader])
        #io = IO.select([@process_reader])

        if io[0].include?(@selfpipe_reader)
          @selfpipe_reader.read_nonblock(1)
 
          while sig = @signal_queue.pop
            signal_handling sig
          end
          puts "*sleep signal"
	  sleep 5
        end

        if io[0].include?(@process_reader)
          @process_reader.read_nonblock(1)
          puts "HUP received"
          puts "*sleep process"
          sleep 5
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
