class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(req)
    return true if @default

    expected = "application/vnd.cobblebot.v#{@version}"
    split_outside_quotes(req.headers['Accept'].to_s, ',').any? do |entry|
      media_type, *parameters = split_outside_quotes(entry, ';').map(&:strip)
      quality = parameters.filter_map do |parameter|
        name, value = parameter.split('=', 2).map(&:strip)
        value.to_f if name.casecmp?('q')
      end.first

      media_type.casecmp?(expected) && quality != 0.0
    end
  end

private
  def split_outside_quotes(value, delimiter)
    parts = ['']
    quoted = false
    escaped = false

    value.each_char do |character|
      if escaped
        parts.last << character
        escaped = false
      elsif character == '\\' && quoted
        parts.last << character
        escaped = true
      elsif character == '"'
        parts.last << character
        quoted = !quoted
      elsif character == delimiter && !quoted
        parts << ''
      else
        parts.last << character
      end
    end

    parts
  end
end
