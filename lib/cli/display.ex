defmodule Wand.CLI.Display.Renderer do
  alias Earmark.Block.{Heading, Html, HtmlOther, Para}
  alias IO.ANSI

  def parse(message) do
    options = %Earmark.Options{
      renderer: Wand.CLI.Display.Renderer,
      smartypants: false,
    }
    # Markdown is dumb and I can't get the normal <space><space>\n to trigger a blank line.
    # Instead, replace \n\n with a zero-width-space character, which Earmark treats as non-space
    String.replace(message, ~r/\n\n/, "\n#{<<0x200B::utf8>>}\n")
    |>Earmark.parse(options)
  end

  def render(blocks, context) do
    mapper = context.options.mapper
    text = mapper.(blocks, &(render_block(&1, context)))
    |> IO.iodata_to_binary()
    {context, text}
  end

  def br(), do: "\n"
  def codespan(text), do: "`#{text}`"
  def em(text), do: ANSI.underline() <> text <> ANSI.no_underline()
  def strong(text), do: ANSI.bright() <> text <> ANSI.normal()

  defp render_block(%Heading{content: content}, _context) do
    [ANSI.underline(), ANSI.bright(), content, ANSI.normal(), ANSI.no_underline(), "\n", "\n"]
  end

  defp render_block(%Para{lnb: lnb, lines: lines}, context) do
    %{value: value} = Earmark.Inline.convert(lines, lnb, context)
    unescape(value) <> "\n"
  end

  defp render_block(%Html{html: ["<pre>" | _] = html}, context) do
    {blocks, _context} = html
    |> tl
    |> List.pop_at(-1)
    |> elem(1)
    |> Enum.join("\n")
    |> parse()

    render(blocks, context)
    |> elem(1)
  end

  defp render_block(%HtmlOther{html: ["<pre>" <> html]}, context) do
    {blocks, _context} = html
    |> String.trim_trailing("</pre>")
    |> parse()

    render(blocks, context)
    |> elem(1)
  end

  defp unescape(text) do
    # Reverse the action of
    # https://github.com/pragdave/earmark/blob/master/lib/earmark/helpers.ex#L56
    text
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end
end

defmodule Wand.CLI.Display do
  @io Wand.CLI.IO.impl()
  def print(message) do
    {blocks, context} = Wand.CLI.Display.Renderer.parse(message)

    formatted = Wand.CLI.Display.Renderer.render(blocks, context)
    |> elem(1)
    |> String.trim_trailing("\n")

    # Always add on a blank newline at the top
    @io.puts("\n" <> formatted)
  end
end
