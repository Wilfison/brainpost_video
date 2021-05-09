# frozen_string_literal: true

require 'open3'

module BrainpostVideo
  class Transcoder
    attr_reader :command, :input

    @@timeout = 30

    class << self
      attr_accessor :timeout
    end

    def initialize(input, output_file, options = EncodingOptions.new, transcoder_options = {})
      if input.is_a?(BrainpostVideo::Movie)
        @movie = input
        @input = input.path
      end
      @output_file = output_file

      @raw_options, @transcoder_options = optimize_screenshot_parameters(options, transcoder_options)

      @errors = []

      apply_transcoder_options

      unless @transcoder_options[:input].nil?
        @input = @transcoder_options[:input]
      end

      input_options = @transcoder_options[:input_options] || []
      iopts = []

      if input_options.is_a?(Array)
        iopts += input_options
      else
        input_options.each { |k, v| iopts += ['-' + k.to_s, v] }
      end

      @command = [BrainpostVideo.ffmpeg_binary, '-y', *iopts, '-i', @input, *@raw_options.to_a, @output_file]
    end

    def run(&block)
      transcode_movie(&block)

      return nil unless @transcoder_options[:validate]

      validate_output_file(&block)
      encoded
    end

    def encoding_succeeded?
      @errors.empty?
    end

    def encoded
      @encoded ||= Movie.new(@output_file) if File.exist?(@output_file)
    end

    def timeout
      self.class.timeout
    end

    private

    # frame=4855 fps= 46 q=31.0 size=45306kB time=00:02:42.28 bitrate=2287.0kbits/
    def transcode_movie
      BrainpostVideo.logger.info("Running transcoding...\n#{command.join(' ')}\n")
      @output = ''

      Open3.popen3(*command) do |_stdin, _stdout, stderr, wait_thr|
        begin
          yield(0.0) if block_given?
          next_line = proc do |line|
            fix_encoding(line)
            @output += line
            if line.include?('time=')
              if line =~ /time=(\d+):(\d+):(\d+.\d+)/ # ffmpeg 0.8 and above style
                time = (Regexp.last_match(1).to_i * 3600) + (Regexp.last_match(2).to_i * 60) + Regexp.last_match(3).to_f
              else # better make sure it wont blow up in case of unexpected output
                time = 0.0
              end

              if @movie
                progress = time / @movie.duration
                yield(progress) if block_given?
              end
            end
          end

          if timeout
            stderr.each_with_timeout(wait_thr.pid, timeout, 'size=', &next_line)
          else
            stderr.each('size=', &next_line)
          end

          unless wait_thr.value.success?
            @errors << 'ffmpeg returned non-zero exit code'
          end
        rescue Timeout::Error => e
          BrainpostVideo.logger.error "Process hung...\n@command\n#{command}\nOutput\n#{@output}\n"
          raise Error, "Process hung. Full output: #{@output}"
        end
      end
    end

    def validate_output_file
      @errors << 'no output file created' unless File.exist?(@output_file)
      @errors << 'encoded file is invalid' if encoded.nil? || !encoded.valid?

      if encoding_succeeded?
        yield(1.0) if block_given?
        BrainpostVideo.logger.info "Transcoding of #{input} to #{@output_file} succeeded\n"
      else
        errors = "Errors: #{@errors.join(', ')}. "
        BrainpostVideo.logger.error "Failed encoding...\n#{command}\n\n#{@output}\n#{errors}\n"
        raise Error, "Failed encoding.#{errors}Full output: #{@output}"
      end
    end

    def apply_transcoder_options
      # if true runs #validate_output_file
      @transcoder_options[:validate] = @transcoder_options.fetch(:validate) { true }

      return if @movie.nil? || @movie.calculated_aspect_ratio.nil?

      case @transcoder_options[:preserve_aspect_ratio].to_s
      when 'width'
        new_height = @raw_options.width / @movie.calculated_aspect_ratio
        new_height = new_height.ceil.even? ? new_height.ceil : new_height.floor
        new_height += 1 if new_height.odd? # needed if new_height ended up with no decimals in the first place
        @raw_options[:resolution] = "#{@raw_options.width}x#{new_height}"
      when 'height'
        new_width = @raw_options.height * @movie.calculated_aspect_ratio
        new_width = new_width.ceil.even? ? new_width.ceil : new_width.floor
        new_width += 1 if new_width.odd?
        @raw_options[:resolution] = "#{new_width}x#{@raw_options.height}"
      end
    end

    def fix_encoding(output)
      output[/test/]
    rescue ArgumentError
      output.force_encoding('ISO-8859-1')
    end

    def optimize_screenshot_parameters(options, transcoder_options)
      # Moves any screenshot seek_time to an 'ss' input_option
      raw_options, input_seek_time = screenshot_seek_time(options)
      screenshot_to_transcoder_options(input_seek_time, transcoder_options)

      [raw_options, transcoder_options]
    end

    def screenshot_seek_time(options)
      # Returns any seek_time for the screenshot and removes it from the options
      # such that the seek time can be moved to an input option for improved BrainpostVideo performance
      if options.is_a?(Array)
        unless options.find_index('-screenshot').nil?
          seek_time_idx = options.find_index('-seek_time')
        end
        unless seek_time_idx.nil?
          options.delete_at(seek_time_idx) # delete 'seek_time'
          input_seek_time = options.delete_at(seek_time_idx).to_s # fetch the seek value
        end
        result = options, input_seek_time
      elsif options.is_a?(Hash)
        raw_options = EncodingOptions.new(options)
        unless raw_options[:screenshot].nil?
          input_seek_time = raw_options.delete(:seek_time).to_s
        end
        result = raw_options, input_seek_time
      else
        raise ArgumentError, "Unknown options format '#{options.class}', should be either EncodingOptions, Hash or Array."
      end
      result
    end

    def screenshot_to_transcoder_options(seek_time, transcoder_options)
      return if seek_time.to_s == ''

      input_options = transcoder_options[:input_options] || []
      # remove ss from input options because we're overriding from seek_time
      if input_options.is_a?(Array)
        fi = input_options.find_index('-ss')
        if fi.nil?
          input_options.concat(['-ss', seek_time])
        else
          input_options[fi + 1] = seek_time
        end
      else
        input_options[:ss] = seek_time
      end
      transcoder_options[:input_options] = input_options
    end
  end
end
