# frozen_string_literal: true

# require 'pry'

module BrainpostVideo
  class AnimateText
    def initialize(animation, xy_location)
      @animation = animation
      @xy_location = xy_location
    end

    def run
      return '' if animation.nil?

      load_animation.to_s
    end

    private

    attr_reader :animation, :xy_location

    # http://ffmpeg.shanewhite.co/
    def fade_in_out
      duration = animation[:duration] || 1
      delay = animation[:delay] || 0
      fade_in = delay + duration

      "alpha='if(lt(t,#{delay}),0,if(lt(t,#{fade_in}),(t-#{delay})/#{duration},if(lt(t,6.4),#{duration},if(lt(t,6.4),(0-(t-6.4))/0,0))))':"
    end

    def load_animation
      return send(animation[:name].to_sym) unless animation[:name].nil?

      ''
    end
  end
end
