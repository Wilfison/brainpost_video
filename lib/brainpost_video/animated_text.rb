# frozen_string_literal: true

require 'pry'

module BrainpostVideo
  class AnimatedText
    attr_reader :command, :input

    @@timeout = 30

    def initialize(output_file, options = EncodingOptions.new, transcoder_options = {})
      @output_file = output_file
      @raw_options = options
      @transcoder_options = transcoder_options
      @errors = []

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

      @command = [BrainpostVideo.ffmpeg_binary, '-y', *iopts, '-loop', '1', '-t', '5', '-i', @input, *@raw_options.to_a, @output_file]
    end

    def run(&block)
      transcode_movie(&block)
      combine_logo unless @transcoder_options[:logo].nil?

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

    private

    def transcode_movie
      BrainpostVideo.logger.info("Running transcoding...\n#{command.join(' ')}\n")
      @output = system(command.join(' '))

      encoded
    end

    def combine_logo
      @output_file = CombineLogo.new(@output_file, @transcoder_options[:logo]).run
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
  end
end
