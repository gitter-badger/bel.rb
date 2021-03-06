#!/usr/bin/env ruby
# bel_rdfschema: Dump RDF schema for BEL.
# usage: bel_rdfschema --format [ntriples | nquads | turtle]

$: << File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')
require 'bel'
require 'optparse'
require 'set'
require 'open-uri'

options = {
  format: 'ntriples'
}
OptionParser.new do |opts|
  opts.banner = '''Dumps RDF schema for BEL.
Usage: bel_rdfschema'''

  opts.on('-f', '--format FORMAT', 'RDF file format.') do |format|
    options[:format] = format.downcase
  end
end.parse!

unless ['ntriples', 'nquads', 'turtle'].include? options[:format]
  $stderr.puts "Format was not one of: ntriples, nquads, or turtle"
  exit 1
end

class Serializer
  attr_reader :writer

  def initialize(stream, format)
    rdf_writer = find_writer(format)
    @writer = rdf_writer.new($stdout, {
        :stream => stream
      }
    )
  end

  def <<(trpl)
    @writer.write_statement(RDF::Statement(*trpl))
  end

  def done
    @writer.write_epilogue
  end

  private

  def find_writer(format)
    case format
      when 'nquads'
        BEL::RDF::RDF::NQuads::Writer
      when 'turtle'
        begin
          require 'rdf/turtle'
          BEL::RDF::RDF::Turtle::Writer
        rescue LoadError
          $stderr.puts """Turtle format not supported.
Install the 'rdf-turtle' gem."""
          raise
        end
      when 'ntriples'
        BEL::RDF::RDF::NTriples::Writer
    end
  end
end

@rdf_writer = ::Serializer.new(true, options[:format])
BEL::RDF::vocabulary_rdf.each do |trpl|
  @rdf_writer << trpl
end
# vim: ts=2 sw=2:
# encoding: utf-8
