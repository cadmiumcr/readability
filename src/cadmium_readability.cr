require "./cadmium/readability"

# TODO: Write documentation for `CadmiumReadability`
module Cadmium
  def self.readability(text)
    Cadmium::Readability.new(text)
  end
end
