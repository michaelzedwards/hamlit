require 'temple'
require 'hamlit/engine'

module Hamlit
  Template = Temple::Templates::Tilt.create(
    Hamlit::Engine,
    register_as: :haml,
    escape_html: true,
  )
end
