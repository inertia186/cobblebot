# Resque 3.0 still calls MultiJSON's deprecated dump/load aliases. Keep the
# stable Resque payload format while using MultiJSON's maintained API.
module ResqueSerialization
  def encode(object)
    MultiJSON.generate(object)
  end

  def decode(object)
    return unless object

    MultiJSON.parse(object)
  rescue MultiJSON::ParseError => error
    raise Resque::Helpers::DecodeException, error.message, error.backtrace
  end
end

Resque.singleton_class.prepend(ResqueSerialization)
