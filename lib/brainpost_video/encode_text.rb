# frozen_string_literal: true

require 'pry'

module BrainpostVideo
  # https://trac.ffmpeg.org/wiki/Xfade
  class EncodeText
    def self.encode_to_feed(texts = [])
      return [] if texts.empty?

      encoded_texts = []
      offset_y = 0
      offset_inverse = texts.sum { |t| t[:font_size].to_i }

      texts.each_with_index do |t, index|
        encoded_texts << encode_text_to_feed(index, t, offset_y, offset_inverse)
        offset_y += t[:font_size].to_i + 5
        offset_inverse -= t[:font_size].to_i
      end

      encoded_params = '"[in]' + encoded_texts.join(', ') + '[out]"'

      ['-vf', encoded_params]
    end

    # drawtext=
    # font='Montserrat Black':
    # text='A imunidade influencia':
    # fontcolor=white:
    # fontsize=40:
    # x=(w-text_w)/2:
    # y=if(lt(t\,3)\,(-h+((3*h-200)*t/6))\,(h-200)/2):
    # enable='between(t,0,5)'
    def self.encode_text_to_feed(index, text = {}, offset_y, offset_inverse)
      return [] if text.empty?

      position = find_text_position(text, index, offset_y, offset_inverse)
      text_config = 'drawtext='
      text_config += text[:font_path] ? "fontfile=#{text[:font_path]}:" : "font='#{text[:font_family]}':"
      text_config += "text='#{satitize_text(text[:text])}':"
      text_config += "fontcolor=#{text[:font_color]}:"
      text_config += "fontsize=#{text[:font_size]}:"
      text_config += "#{position}:"

      unless text[:box_color].nil?
        text_config += 'box=1:'
        text_config += "boxcolor=#{text[:box_color]}:"
        text_config += 'boxborderw=10:'
      end

      # text_config += "enable='between(t,1,5)'"
      text_config += AnimateText.new(text[:animation], position).run
      text_config
    end

    def self.satitize_text(text)
      return '' if text.empty?

      text = text.gsub(':', ';')
      text
    end

    # Top left: x=0:y=0 (with 40 pixel padding x=40:y=40)
    # Top center: x=(w-text_w)/2:y=0 (with 40 px padding x=(w-text_w)/2:y=40)
    # Top right: x=w-tw:y=0 (with 40 px padding: x=w-tw-40:y=40)
    # Centered: x=(w-text_w)/2:y=(h-text_h)/2
    # Bottom left: x=0:y=h-th (with 40 px padding: x=40:y=h-th-40)
    # Bottom center: x=(w-text_w)/2:y=h-th (with 40 px padding: x=(w-text_w)/2:y=h-th-40)
    # Bottom right: x=w-tw:y=h-th (with 40 px padding: x=w-tw-40:y=h-th-40)
    def self.find_text_position(text, index, offset_y, offset_inverse)
      case text[:position]
      when 'text_up_left'
        return 'x=40:y=75' if index.zero?

        "x=40:y=(75+#{offset_y})"
      when 'text_up_right'
        return 'x=w-tw-40:y=75' if index.zero?

        "x=w-tw-40:y=(75+#{offset_y})"
      when 'text_down_left'
        return "x=40:y=(h-th-75-#{offset_inverse})" if index.zero?

        "x=40:y=(h-th-75-#{offset_inverse})"
      when 'text_down_right'
        return "x=w-tw-40:y=(h-th-75-#{offset_inverse})" if index.zero?

        "x=w-tw-40:y=(h-th-75-#{offset_inverse})"
      when 'text_down_midle'
        return "x=(w-text_w)/2:y=(h-th-80-#{offset_inverse})" if index.zero?

        "x=(w-text_w)/2:y=(h-th-80-#{offset_inverse})"
      else
        return 'x=(w-text_w)/2:y=(h-text_h)/2' if index.zero?

        "x=(w-text_w)/2:y=((h-text_h)/2)+#{offset_y}"
      end
    end
  end
end
