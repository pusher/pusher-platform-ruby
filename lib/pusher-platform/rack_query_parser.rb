# Taken from https://github.com/rack/rack
# sha: 5559676e7b5a3107d39552285ce8b714b672bde6
#
# The MIT License (MIT)
#
# Copyright (C) 2007-2018 Christian Neukirchen <http://chneukirchen.org/infopage.html>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'uri'

module PusherPlatform
  class QueryParser
    DEFAULT_SEP = /[&;] */n
    COMMON_SEP = { ";" => /[;] */n, ";," => /[;,] */n, "&" => /[&] */n }

    # ParameterTypeError is the error that is raised when incoming structural
    # parameters (parsed by parse_nested_query) contain conflicting types.
    class ParameterTypeError < TypeError; end

    # InvalidParameterError is the error that is raised when incoming structural
    # parameters (parsed by parse_nested_query) contain invalid format or byte
    # sequence.
    class InvalidParameterError < ArgumentError; end

    def self.make_default(key_space_limit, param_depth_limit)
      new Params, key_space_limit, param_depth_limit
    end

    attr_reader :key_space_limit, :param_depth_limit

    def initialize(params_class, key_space_limit, param_depth_limit)
      @params_class = params_class
      @key_space_limit = key_space_limit
      @param_depth_limit = param_depth_limit
    end

    # Stolen from Mongrel, with some small modifications:
    # Parses a query string by breaking it up at the '&'
    # and ';' characters.  You can also use this to parse
    # cookies by changing the characters used in the second
    # parameter (which defaults to '&;').
    def parse_query(qs, d = nil, &unescaper)
      unescaper ||= method(:unescape)

      params = make_params

      (qs || '').split(d ? (COMMON_SEP[d] || /[#{d}] */n) : DEFAULT_SEP).each do |p|
        next if p.empty?
        k, v = p.split('=', 2).map!(&unescaper)

        if cur = params[k]
          if cur.class == Array
            params[k] << v
          else
            params[k] = [cur, v]
          end
        else
          params[k] = v
        end
      end

      return params.to_params_hash
    end

    # parse_nested_query expands a query string into structural types. Supported
    # types are Arrays, Hashes and basic value types. It is possible to supply
    # query strings with parameters of conflicting types, in this case a
    # ParameterTypeError is raised. Users are encouraged to return a 400 in this
    # case.
    def parse_nested_query(qs, d = nil)
      return {} if qs.nil? || qs.empty?
      params = make_params

      (qs || '').split(d ? (COMMON_SEP[d] || /[#{d}] */n) : DEFAULT_SEP).each do |p|
        k, v = p.split('=', 2).map! { |s| unescape(s) }

        normalize_params(params, k, v, param_depth_limit)
      end

      return params.to_params_hash
    rescue ArgumentError => e
      raise InvalidParameterError, e.message
    end

    # normalize_params recursively expands parameters into structural types. If
    # the structural types represented by two different parameter names are in
    # conflict, a ParameterTypeError is raised.
    def normalize_params(params, name, v, depth)
      raise RangeError if depth <= 0

      name =~ %r(\A[\[\]]*([^\[\]]+)\]*)
      k = $1 || ''
      after = $' || ''

      if k.empty?
        if !v.nil? && name == "[]"
          return Array(v)
        else
          return
        end
      end

      if after == ''
        params[k] = v
      elsif after == "["
        params[name] = v
      elsif after == "[]"
        params[k] ||= []
        raise ParameterTypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        params[k] << v
      elsif after =~ %r(^\[\]\[([^\[\]]+)\]$) || after =~ %r(^\[\](.+)$)
        child_key = $1
        params[k] ||= []
        raise ParameterTypeError, "expected Array (got #{params[k].class.name}) for param `#{k}'" unless params[k].is_a?(Array)
        if params_hash_type?(params[k].last) && !params_hash_has_key?(params[k].last, child_key)
          normalize_params(params[k].last, child_key, v, depth - 1)
        else
          params[k] << normalize_params(make_params, child_key, v, depth - 1)
        end
      else
        params[k] ||= make_params
        raise ParameterTypeError, "expected Hash (got #{params[k].class.name}) for param `#{k}'" unless params_hash_type?(params[k])
        params[k] = normalize_params(params[k], after, v, depth - 1)
      end

      params
    end

    def make_params
      @params_class.new @key_space_limit
    end

    def new_space_limit(key_space_limit)
      self.class.new @params_class, key_space_limit, param_depth_limit
    end

    def new_depth_limit(param_depth_limit)
      self.class.new @params_class, key_space_limit, param_depth_limit
    end

    private

    def params_hash_type?(obj)
      obj.kind_of?(@params_class)
    end

    def params_hash_has_key?(hash, key)
      return false if key =~ /\[\]/

      key.split(/[\[\]]+/).inject(hash) do |h, part|
        next h if part == ''
        return false unless params_hash_type?(h) && h.key?(part)
        h[part]
      end

      true
    end

    def unescape(s)
      URI.decode_www_form_component(s, Encoding::UTF_8)
    end

    class Params
      def initialize(limit)
        @limit  = limit
        @size   = 0
        @params = {}
      end

      def [](key)
        @params[key]
      end

      def []=(key, value)
        @size += key.size if key && !@params.key?(key)
        raise RangeError, 'exceeded available parameter key space' if @size > @limit
        @params[key] = value
      end

      def key?(key)
        @params.key?(key)
      end

      def to_params_hash
        hash = @params
        hash.keys.each do |key|
          value = hash[key]
          if value.kind_of?(self.class)
            if value.object_id == self.object_id
              hash[key] = hash
            else
              hash[key] = value.to_params_hash
            end
          elsif value.kind_of?(Array)
            value.map! {|x| x.kind_of?(self.class) ? x.to_params_hash : x}
          end
        end
        hash
      end
    end
  end
end
