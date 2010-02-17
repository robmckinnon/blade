require 'rubygems'; require 'hpricot'; require 'open-uri'
require '../../acts_as_proper_noun_identifier.rb'
require 'morph'

xml = open('registry.xml').read

hash = Hash.from_xml xml

entries = Morph.from_hash hash
# doc = Hpricot xml
entries.entries.first.categories.categories.first.items

For each item in directorships -> get companies
For each
