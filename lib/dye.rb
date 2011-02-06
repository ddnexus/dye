class Module

  def define_dye_method(custom_styles={})
    define_method(:dye) do |*args|
      Dye.send :apply_styles, custom_styles, *args
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
  alias_method :strict_ansi?, :strict_ansi

  def dye(*args)
    apply_styles( {}, *args )
  end

  def strip_ansi(string)
    string.gsub(/\e\[[\d;]+m/, '')
  end

  def sgr(*names)
    return if names.empty?
    codes = names.map{|n| sgr_to_code(n) }
    strict_ansi? ? "\e[#{codes.join(';')}m" : codes.map{|c| "\e[#{c}m" }.join
  end

  private

  def apply_styles(custom_styles, *args)
    if args[1].is_a?(String)
      string, no_color_string, *names = args
    else
      string, *names = args
    end
    return no_color_string||string unless color?
    codes = names.map do |name|
              sgr = custom_styles.has_key?(name) ? custom_styles[name] : name
              sgr = [sgr] unless sgr.is_a?(Array)
              sgr.map do |n|
                next if n.nil?
                sgr_to_code(n)
              end
            end.flatten.compact
    return string if codes.empty?
    if strict_ansi?
      string.match(/^\e\[[\d;]+m.*\e\[0m$/m) ?
        string.sub(/^(\e\[[\d;]+)/, '\1;' + codes.join(';')) :
        sprintf("\e[0;%sm%s\e[0m", codes.join(';'), string)
    else
      string.match(/^(?:\e\[\d+m)+.*\e\[0m$/m) ?
        string.sub(/^((?:\e\[\d+m)+)/, '\1' + codes.map{|c| "\e[#{c}m" }.join) :
        sprintf("\e[0m%s%s\e[0m", codes.map{|c| "\e[#{c}m" }.join, string)
    end
  end

  def sgr_to_code(name)
    code = name.is_a?(Symbol) ? BASIC_SGR[name] : name
    raise UnknownSgrCode.new(code) unless code.is_a?(Integer) && (0..109).include?(code)
    code
  end

end
