require "./cadmium/readability"
require "cadmium_tokenizer"

# TODO: Write documentation for `CadmiumReadability`
module Cadmium
  def self.readability(text)
    Cadmium::Readability.new(text)
  end
end
