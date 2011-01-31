class Object

  def define_dye_method(custom_styles={})
    define_method(:dye) do |string, *names|
      return string unless Dye.color?
      codes = names.map do |name|
                case
                when custom_styles.has_key?(name)
                  Dye.sgr_names_to_codes *custom_styles[name]
                when Dye::BASIC_SGR.has_key?(name)
                  Dye::BASIC_SGR[name]
                else
                  raise Dye::UnknownSgrCode.new(name)
                end
              end.flatten
      Dye.apply_codes string, *codes
    end
  end

end


module Dye

  extend self

  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip

  class UnknownSgrCode < Exception
    def initialize(sgr)
      super("#{sgr.inspect} is unknown")
    end
  end

  # Select Graphic Rendition
  BASIC_SGR = {
    :clear     => 0,
    :bold      => 1,
    :underline => 4,
    :blinking  => 5,
    :reversed  => 7,

    :black     => 30,
    :red       => 31,
    :green     => 32,
    :yellow    => 33,
    :blue      => 34,
    :magenta   => 35,
    :cyan      => 36,
    :white     => 37,

    :onblack   => 40,
    :onred     => 41,
    :ongreen   => 42,
    :onyellow  => 43,
    :onblue    => 44,
    :onmagenta => 45,
    :oncyan    => 46,
    :onwhite   => 47
  }

  @color = !!STDOUT.tty? && !!ENV['TERM'] && ENV['TERM'] != 'dumb'
  attr_accessor :color
  alias_method :color?, :color

  @strict_ansi = !!ENV['DYE_STRICT_ANSI']
  attr_accessor :strict_ansi

  def dye(string, *sgr_names)
    return string unless color?
    apply_codes string, sgr_names_to_codes(*sgr_names)
  end

  def strip_ansi(string)
    string.gsub(/\e\[[\d;]+m/, '')
  end

  def sgr_names_to_codes(*names)
    names.map do |n|
      next if n.nil?
      code = n.is_a?(Symbol) ? BASIC_SGR[n] : n
      raise UnknownSgrCode.new(n) unless code.is_a?(Integer) && (0..109).include?(code)
      code
    end
  end

  def apply_codes(string, *codes)
    codes.compact!
    return string if codes.empty?
    if strict_ansi
      string.match(/^\e\[[\d;]+m.*\e\[0m$/m) ?
        string.sub(/^(\e\[[\d;]+)/, '\1;' + codes.join(';')) :
        sprintf("\e[0;%sm%s\e[0m", codes.join(';'), string)
    else
      string.match(/^(?:\e\[\d+m)+.*\e\[0m$/m) ?
        string.sub(/^((?:\e\[\d+m)+)/, '\1' + codes.map{|c| "\e[#{c}m" }.join) :
        sprintf("\e[0m%s%s\e[0m", codes.map{|c| "\e[#{c}m" }.join, string)
    end
  end
end
