require 'hamlit/compilers/attributes'
require 'hamlit/compilers/doctype'
require 'hamlit/compilers/dynamic'
require 'hamlit/compilers/filter'
require 'hamlit/compilers/preserve'
require 'hamlit/compilers/script'
require 'hamlit/compilers/strip'
require 'hamlit/compilers/tag'
require 'hamlit/compilers/text'
require 'temple/html/filter'

module Hamlit
  class Compiler < Temple::HTML::Filter
    include Compilers::Attributes
    include Compilers::Doctype
    include Compilers::Dynamic
    include Compilers::Filter
    include Compilers::Preserve
    include Compilers::Script
    include Compilers::Strip
    include Compilers::Tag
    include Compilers::Text
  end
end
