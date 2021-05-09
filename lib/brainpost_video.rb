# frozen_string_literal: true

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'stringio'

require 'brainpost_video/version'
require 'brainpost_video/errors'
require 'brainpost_video/movie'
require 'brainpost_video/io_monkey'
require 'brainpost_video/transcoder'
require 'brainpost_video/animated_text'
require 'brainpost_video/animate_text'
require 'brainpost_video/encode_text'
require 'brainpost_video/combine_logo'
require 'brainpost_video/encoding_options'

module BrainpostVideo
  # BrainpostVideo logs information about its progress when it's transcoding.
  # Jack in your own logger through this method if you wish to.
  #
  # @param [Logger] log your own logger
  # @return [Logger] the logger you set
  def self.logger=(log)
    @logger = log
  end

  # Get BrainpostVideo logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    @logger = logger
  end

  # Set the path of the ffmpeg binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffmpeg
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  # @raise Errno::ENOENT if the ffmpeg binary cannot be found
  def self.ffmpeg_binary=(bin)
    if bin.is_a?(String) && !File.executable?(bin)
      raise Errno::ENOENT, "the ffmpeg binary, \'#{bin}\', is not executable"
    end

    @ffmpeg_binary = bin
  end

  # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
  #
  # @return [String] the path to the ffmpeg binary
  # @raise Errno::ENOENT if the ffmpeg binary cannot be found
  def self.ffmpeg_binary
    @ffmpeg_binary || which('ffmpeg')
  end

  # Get the path to the ffprobe binary, defaulting to what is on ENV['PATH']
  #
  # @return [String] the path to the ffprobe binary
  # @raise Errno::ENOENT if the ffprobe binary cannot be found
  def self.ffprobe_binary
    @ffprobe_binary || which('ffprobe')
  end

  # Set the path of the ffprobe binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffprobe
  #
  # @param [String] path to the ffprobe binary
  # @return [String] the path you set
  # @raise Errno::ENOENT if the ffprobe binary cannot be found
  def self.ffprobe_binary=(bin)
    if bin.is_a?(String) && !File.executable?(bin)
      raise Errno::ENOENT, "the ffprobe binary, \'#{bin}\', is not executable"
    end

    @ffprobe_binary = bin
  end

  # Get the maximum number of http redirect attempts
  #
  # @return [Integer] the maximum number of retries
  def self.max_http_redirect_attempts
    @max_http_redirect_attempts.nil? ? 10 : @max_http_redirect_attempts
  end

  # Set the maximum number of http redirect attempts.
  #
  # @param [Integer] the maximum number of retries
  # @return [Integer] the number of retries you set
  # @raise Errno::ENOENT if the value is negative or not an Integer
  def self.max_http_redirect_attempts=(v)
    if v && !v.is_a?(Integer)
      raise Errno::ENOENT, 'max_http_redirect_attempts must be an integer'
    end
    if v && v < 0
      raise Errno::ENOENT, 'max_http_redirect_attempts may not be negative'
    end

    @max_http_redirect_attempts = v
  end

  # Cross-platform way of finding an executable in the $PATH.
  #
  #   which('ruby') #=> /usr/bin/ruby
  # see: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      end
    end
    raise Errno::ENOENT, "the #{cmd} binary could not be found in #{ENV['PATH']}"
  end
end
