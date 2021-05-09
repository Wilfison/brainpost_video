# frozen_string_literal: true

# https://ottverse.com/crossfade-between-videos-ffmpeg-xfade-filter/
module BrainpostVideo
  class CombineLogo
    def initialize(video_path, logo = {})
      @video_path = video_path
      @logo = logo
    end

    def run
      return video_path if logo[:path].nil?

      transcode_logo
      transcode_movie
    end

    private

    attr_reader :video_path, :logo

    def transcode_movie
      BrainpostVideo.logger.info("Running combine...\n#{command.join(' ')}\n")

      @output = system(command.join(' '))

      output_file
    end

    def transcode_logo
      command_logo = [BrainpostVideo.ffmpeg_binary, '-y', '-loop', '1', '-t', '3', '-i', logo[:path], logo_video_file]
      BrainpostVideo.logger.info("Running logo...\n#{command_logo.join(' ')}\n")

      system(command_logo.join(' '))
    end

    def transition
      return logo[:transition] if avaliable_transitions.include? logo[:transition]
      return avaliable_transitions.sample if logo[:transition] == 'random'

      'fade'
    end

    def output_file
      video_path.sub('.mp4', '_final.mp4')
    end

    def logo_video_file
      video_path.sub('.mp4', '_logo.mp4')
    end

    def command
      @command ||= [
        BrainpostVideo.ffmpeg_binary,
        '-y',
        '-i', video_path,
        '-i', logo_video_file,
        '-filter_complex',
        "xfade=transition=#{transition}:duration=0.5:offset=4.5",
        output_file
      ]
    end

    # https://trac.ffmpeg.org/wiki/Xfade
    def avaliable_transitions
      %w[
        fade
        wipeleft
        wiperight
        wipeup
        wipedown
        slideleft
        slideright
        slideup
        slidedown
        circlecrop
        rectcrop
        distance
        fadeblack
        fadewhite
        radial
        smoothleft
        smoothright
        smoothup
        smoothdown
        circleopen
        circleclose
        vertopen
        vertclose
        horzopen
        horzclose
        dissolve
        pixelize
        diagtl
        diagtr
        diagbl
        diagbr
        hlslice
        hrslice
        vuslice
        vdslice
        hblur
        fadegrays
        wipetl
        wipetr
        wipebl
        wipebr
        squeezeh
        squeezev
      ]
    end
  end
end
