# frozen_string_literal: true

require_relative '../lib/brainpost_video'

# use custom ffmpeg version
# BrainpostVideo.ffmpeg_binary = '$HOME/app/ffmpeg/ffmpeg'

current_path = File.expand_path(File.dirname(__FILE__))

text_options = [
  {
    font_family: 'Ubuntu',
    font_path: '/usr/share/fonts/truetype/ubuntu/Ubuntu-M.ttf',
    text: 'Como funciona o',
    font_color: '#4f2687',
    font_size: 30,
    position: 'text_up_left',
    box_color: nil,
    animation: {
      name: 'fade_in_out',
      delay: 0,
      fade_in_duration: 1
    }
  },
  {
    font_family: 'Ubuntu',
    font_path: '/usr/share/fonts/truetype/ubuntu/Ubuntu-M.ttf',
    text: 'tratamento com',
    font_color: '#4f2687',
    font_size: 30,
    position: 'text_up_left',
    box_color: nil,
    animation: {
      name: 'fade_in_out',
      delay: 0.4,
      fade_in_duration: 1
    }
  },
  {
    font_family: 'Ubuntu-Bold',
    font_path: '/usr/share/fonts/truetype/ubuntu/Ubuntu-B.ttf',
    text: 'Invisaling?',
    font_color: '#4f2687',
    font_size: 40,
    position: 'text_up_left',
    animation: {
      name: 'fade_in_out',
      delay: 0.9,
      fade_in_duration: 1
    }
  }
]

logo_options = {
  path: "#{current_path}/assets/logo.png",
  transition: 'hblur'
}

slideshow_transcoder = BrainpostVideo::AnimatedText.new(
  "#{current_path.split('/')[0..-2].join('/')}/tmp/slideshow.mp4",
  BrainpostVideo::EncodeText.encode_to_feed(text_options),
  input: "#{current_path}/assets/bp.png",
  logo: logo_options
)

slideshow_transcoder.run

# `xdg-open slideshow_final.mp4`
