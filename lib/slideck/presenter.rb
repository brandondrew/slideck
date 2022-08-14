# frozen_string_literal: true

module Slideck
  # Responsible for presenting slides
  #
  # @api private
  class Presenter
    # Create a Presenter
    #
    # @param [TTY::Reader] reader
    #   the keyboard input reader
    # @param [Slideck::Renderer] renderer
    #   the slides renderer
    # @param [Slideck::Tracker] tracker
    #   the tracker for slides
    # @param [IO] output
    #   the output stream for the slides
    #
    # @api public
    def initialize(reader, renderer, tracker, output)
      @reader = reader
      @renderer = renderer
      @tracker = tracker
      @output = output
      @stop = false
      @buffer = []
    end

    # Start presentation
    #
    # @example
    #   presenter.start(slides)
    #
    # @param [Array<String>] slides
    #   the slides to present
    #
    # @return [void]
    #
    # @api public
    def start(slides)
      @reader.subscribe(self)
      @output.print @renderer.cursor.hide

      until @stop
        clear_screen
        render_slide(slides[@tracker.current])
        @reader.read_keypress
      end
    ensure
      @output.print @renderer.cursor.show
    end

    # Render current slide
    #
    # @param [String] slide
    #   the slide to render
    #
    # @return [void]
    #
    # @api private
    def render_slide(slide)
      @output.print @renderer.render(slide, @tracker.current + 1,
                                     @tracker.total)
    end

    # Clear terminal screen
    #
    # @return [void]
    #
    # @api private
    def clear_screen
      @output.print @renderer.clear
    end

    # Handle a keypress event
    #
    # @param [TTY::Reader::KeyEvent] event
    #   the key event
    #
    # @return [void]
    #
    # @api private
    def keypress(event)
      case event.value
      when "n", "l" then keyright
      when "p", "h" then keyleft
      when "^" then go_to_first
      when "$" then go_to_last
      when "g" then go_to_slide
      when /\d/ then add_to_buffer(event.value)
      when "q" then keyctrl_x
      end
    end

    # Navigate to the next slide
    #
    # @return [void]
    #
    # @api private
    def keyright(*)
      @tracker = @tracker.next
    end
    alias keyspace keyright
    alias keypage_down keyright

    # Navigate to the previous slide
    #
    # @return [void]
    #
    # @api private
    def keyleft(*)
      @tracker = @tracker.previous
    end
    alias keybackspace keyleft
    alias keypage_up keyleft

    # Exit presentation
    #
    # @return [void]
    #
    # @api private
    def keyctrl_x(*)
      clear_screen
      @stop = true
    end
    alias keyescape keyctrl_x

    # Navigate to the fist slide
    #
    # @return [void]
    #
    # @api private
    def go_to_first
      @tracker = @tracker.first
    end

    # Navigate to the last slide
    #
    # @return [void]
    #
    # @api private
    def go_to_last
      @tracker = @tracker.last
    end

    # Navigate to a given slide
    #
    # @return [void]
    #
    # @api private
    def go_to_slide
      @tracker = @tracker.go_to(@buffer.join.to_i - 1)
      @buffer.clear
    end

    # Add to the input buffer
    #
    # @param [String] input_key
    #   the input key
    #
    # @return [void]
    #
    # @api private
    def add_to_buffer(input_key)
      @buffer += [input_key]
    end
  end # Presenter
end # Slideck
