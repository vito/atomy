class Rubinius::Location
  attr_reader :receiver
end

class Exception
  def awesome_backtrace
    @awesome_backtrace ||= Atomy::Backtrace.backtrace(@locations)
  end
end

module Atomy
  class Backtrace < Rubinius::Backtrace
    def location_color(loc, first, macro)
      return "\e[0;92m" if first && macro
      return @first_color if first
      return "\e[0;32m" if macro

      atomy_root = File.expand_path("../../../", __FILE__)
      if loc.prefix? atomy_root
        loc.slice!(0, atomy_root.size + 1)
      end

      if loc =~ /^lib\/atomy/
        "\e[0;36m"
      elsif loc =~ /^kernel\/.*\.ay/
        "\e[0;36m"
      else
        color_from_loc(loc, first)
      end
    end

    def show(sep="\n", show_color=true)
      first = true

      show_color = false unless @colorize
      if show_color
        clear = "\033[0m"
      else
        clear = ""
      end

      max = 0
      lines = []
      last_method = nil
      last_line = nil
      last_name = nil
      times = 0

      @locations.each do |loc|
        next if loc.file == "__wrapper__"

        if loc.name == last_name and loc.method == last_method \
                                and loc.line == last_line
          times += 1
        else
          lines.last[-2] = times if lines.size > 0
          last_method = loc.method
          last_line = loc.line
          last_name = loc.name

          if loc.receiver.is_a?(Atomy::Module) &&
                loc.method.name.to_s.start_with?("_expand")
            vars = loc.variables
            node_idx = vars.method.local_names.to_a.index(:node)
            node = vars.locals[node_idx]

            ctx =
              if node.file
                "#{File.basename(node.file)}:#{node.line}"
              else
                "#{node.class.name.split("::").last}@#{node.line}"
              end

            str = "expand(#{ctx})"
            macro = true
          elsif loc.receiver.is_a?(Atomy::Module) &&
                  loc.is_block && loc.name == :__script__ &&
                  loc.method.name != :__block__
            str = "#{loc.receiver.name}\#__script__"
            macro = false
          else
            str = loc.describe
            macro = false
          end

          max = str.size if str.size > max

          lines << [str, loc, 1, macro]
          times = 0
        end
      end

      max_width = (@width * (MAX_WIDTH_PERCENTAGE / 100.0)).to_i
      max = max_width if max > max_width

      str = ""
      lines.each do |recv, location, rec_times, macro|
        pos  = location.position(Dir.getwd)
        color = show_color ? location_color(pos, first, macro) : ""
        first = false # special handling for first line

        spaces = max - recv.size
        spaces = 0 if spaces < 0

        if show_color and location.inlined?
          start = " #{' ' * spaces}#{recv} #{@inline_effect}at#{clear}#{color} "
        else
          start = " #{' ' * spaces}#{recv} at "
        end

        # start.size without the escapes
        start_size = 1 + spaces + recv.size + 4

        line_break = @width - start_size - 1
        line_break = nil if line_break < @min_width

        if line_break and pos.size >= line_break
          indent = start_size

          new_pos = ""
          bit = ""
          parts = pos.split("/")
          file = parts.pop

          first = true
          parts.each do |part|
            if bit.size + part.size > line_break
              new_pos << bit << "\n" << (' ' * indent)
              bit = ""
            end

            bit << "/" unless first
            first = false
            bit << part
          end

          new_pos << bit
          if bit.size + file.size > line_break
            new_pos << "\n" << (' ' * indent)
          end
          new_pos << "/" << file
          str << color
          str << start
          str << new_pos
          str << clear
        else
          if start_size > @width - @min_width
            str << "#{color} #{start}\\\n          #{pos}#{clear}"
          else
            str << "#{color} #{start}#{pos}#{clear}"
          end
        end

        if rec_times > 1
          str << " (#{rec_times} times)"
        end

        if location.is_jit and $DEBUG
          str << " (jit)"
        end

        str << sep
      end

      return str
    end
  end
end
