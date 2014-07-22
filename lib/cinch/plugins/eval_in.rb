# -*- coding: utf-8 -*-
require 'cinch'

require 'uri'
require 'net/http'
require 'nokogiri'

module Cinch::Plugins
  class EvalIn
    include Cinch::Plugin
    match(/\A(\d*)>>(.*)\z/, :prefix => "")

    class FormatError < StandardError; end
    class CommunicationError < StandardError; end

    ServiceURI = URI("https://eval.in/")

    KnownVersions = {
      "10" => "ruby/mri-1.0",
      "18" => "ruby/mri-1.8.7",
      "19" => "ruby/mri-1.9.3",
      "20" => "ruby/mri-2.0.0",
      "21" => "ruby/mri-2.1",
    }

    DefaultVersion = "21"

    MaxLength = 80

    def execute(m, version, code)
      version = DefaultVersion if version.empty?

      if !KnownVersions.has_key?(version)
        m.reply("Unknown version number --- #{version}", true)
      else
        m.reply("=> #{evaluate(KnownVersions[version], code)}", true)
      end
    rescue
      m.reply("Something went wrong when trying to evaluate your code.", true)
      raise $! # Cinch takes care of logging exceptions
    end

    def evaluate(version, code)
      templated_code = if version == "ruby/mri-1.0"
                         old_template(code)
                       else
                         new_template(code)
                       end

      result = Net::HTTP.post_form(ServiceURI,
                                   "utf8" => "λ",
                                   "code" => templated_code,
                                   "execute" => "on",
                                   "lang" => version,
                                   "input" => "")

      if result.is_a? Net::HTTPFound
        location = URI(result['location'])
        location.scheme = "https"
        location.port = 443

        body = Nokogiri(Net::HTTP.get(location))

        if output_title = body.at_xpath("*//h2[text()='Program Output']")
          output = output_title.next_element.text
          first_line = output.each_line.first.chomp
          needs_ellipsis = output.each_line.count > 1 ||
            first_line.length > MaxLength

          "#{first_line[0, MaxLength]}#{'...' if needs_ellipsis} "\
          "(#{location})"
        else
          raise FormatError, "couldn't find program output"
        end
      else
        raise CommunicationError, result
      end
    end

    def old_template(code)
      <<eot
begin
  $stdout.puts((#{code}).inspect)
rescue Exception
   $stderr.puts "\#{$!.type}: \#{$!}"
end
eot
    end

    def new_template(code)
      <<eot
begin
  puts eval(DATA.read).inspect
rescue Exception => e
  $stderr.puts "\#{e.class}: \#{e}"
end
__END__
#{code}
eot
    end
  end
end
