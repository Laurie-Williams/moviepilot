#!/usr/bin/env ruby
require "bundler"
require "open-uri"
Bundler.require

# Curses Config
Curses.noecho
Curses.stdscr.keypad(true)
Curses.nonl
Curses.raw
Curses.init_screen
Curses.start_color
Curses.init_pair(1,Curses::COLOR_BLACK,Curses::COLOR_YELLOW)
Curses.init_pair(2,Curses::COLOR_RED,Curses::COLOR_BLACK)
Curses.init_pair(3,Curses::COLOR_WHITE,Curses::COLOR_BLACK)
Curses.init_pair(4,Curses::COLOR_MAGENTA,Curses::COLOR_BLACK)
Curses.init_pair(5,Curses::COLOR_BLUE,Curses::COLOR_BLACK)
Curses.init_pair(6,Curses::COLOR_GREEN,Curses::COLOR_BLACK)
# inverted
Curses.init_pair(7,Curses::COLOR_WHITE,Curses::COLOR_RED)
Curses.init_pair(8,Curses::COLOR_BLACK,Curses::COLOR_GREEN)
Curses.init_pair(9,Curses::COLOR_WHITE,Curses::COLOR_MAGENTA)
Curses.init_pair(10,Curses::COLOR_WHITE,Curses::COLOR_BLUE)


class Display
  def initialize()
    @selected_category = "superheroes"
    @categories = ["superheroes", "tv", "horror", "young-adult"]
    @articles = nil
    @page = :list
  end

  def run
    build_display
  end

private

  def set_nav_listener
    loop do
      case Curses.getch
        when Curses::Key::RIGHT
          if @page == :list
            move_right
            Curses.setpos(0, 0)
            Curses.attron(set_color) do
              print_menu
            end
            Curses.setpos(2,0)
            print_results
          end
        when Curses::Key::LEFT
          if @page == :list
            move_left
            Curses.setpos(0, 0)
            Curses.attron(set_color) do
              print_menu
            end
            Curses.setpos(2,0)
            print_results
          end
        when Curses::Key::UP
          if @page == :list
            move_up
            Curses.setpos(2,0)
            print_results
          end
        when Curses::Key::DOWN
          if @page == :list
            move_down
            Curses.setpos(2,0)
            print_results
          end
        when 13 #ENTER
          if @page == :list
            Curses.clear
            Curses.setpos(0,0)
            Curses.attron(set_color) do
              print_menu
            end
            print_article
            @page = :article
          elsif @page == :article
            open_article(@selected_article)
          end
        when 127 #BACKSPACE
          Curses.setpos(2,0)
          print_results
          @page = :list
        when "q"  #BACKSPACE
          display.exit
      end
    end
  end

  def set_color
    case @selected_category
      when "superheroes"
        Curses.color_pair(2)
      when "tv"
        Curses.color_pair(6)
      when "horror"
        Curses.color_pair(4)
      when "young-adult"
        Curses.color_pair(5)
    end
  end

  def set_inverse
    case @selected_category
      when "superheroes"
        Curses.color_pair(7)
      when "tv"
        Curses.color_pair(8)
      when "horror"
        Curses.color_pair(9)
      when "young-adult"
        Curses.color_pair(10)
    end
  end

  def move_right
    index = @categories.index(@selected_category)
    if @selected_category == @categories.last
      @selected_category = @categories.first
    else
      @selected_category = @categories[index + 1]
    end
    @articles = get_results_for(@selected_category)
  end

  def move_left
    index = @categories.index(@selected_category)
    if index == 0
      @selected_category = @categories.last
    else
      @selected_category = @categories[index - 1]
    end
    @articles = get_results_for(@selected_category)
  end

  def move_up
    index = @articles.index(@selected_article)
    if index == 0
      @selected_article = @articles.last
    else
      @selected_article = @articles[index - 1]
    end
  end

  def move_down
    index = @articles.index(@selected_article)
    if @selected_article == @articles.last
      @selected_article = @articles.first
    else
      @selected_article = @articles[index + 1]
    end
  end

  def build_display
    @articles = get_results_for(@selected_category)
    Curses.setpos(0, 0)
    Curses.attron(set_color) do
      print_menu
    end
    print_results
    set_nav_listener
    Curses.refresh
  end

  def print_menu
      @categories.each do |category |
        print_category(category)
      end
    Curses.addstr("\n\n")
  end

  def print_category(category)
    if @selected_category == category
      Curses.attron(set_inverse) do
        Curses.addstr("|#{category}|")
      end
    else
      Curses.addstr("|#{category}|")
    end
    Curses.addstr(" - ") if category != @categories.last
  end

  def print_results
    @articles.each do |movie|
      if @selected_article == movie
        Curses.attron(Curses::A_STANDOUT) do
          Curses.addstr("Title: #{movie["title"]}: \n")
          Curses.attron(Curses.color_pair(5)) do
            Curses.addstr("( Author: #{movie["author"]["name"]} )")
          end
          Curses.attron(Curses.color_pair(6)) do
            Curses.addstr("( #{movie["tower_data"]["reads"]} Reads! )\n \n")
          end
        end
      else
        Curses.addstr("Title: #{movie["title"]}: \n")
        Curses.attron(Curses.color_pair(5)) do
          Curses.addstr("( Author: #{movie["author"]["name"]} )")
        end
        Curses.attron(Curses.color_pair(6)) do
          Curses.addstr("( #{movie["tower_data"]["reads"]} Reads! )\n \n")
        end
      end
    end
  end

  def print_article
    Curses.attron(Curses::A_UNDERLINE) do
      Curses.addstr("Title: #{@selected_article["title"]}: \n")
    end
    Curses.attron(Curses.color_pair(5)) do
      Curses.addstr("( Author: #{@selected_article["author"]["name"]} )")
    end
    Curses.attron(Curses.color_pair(6)) do
      Curses.addstr("( #{@selected_article["tower_data"]["reads"]} Reads! )\n \n")
    end
    Curses.attron(Curses.color_pair(6)) do
      Curses.addstr("----PRESS ENTER AGAIN TO OPEN IN BROWSER---- \n\n")
    end

    article_text(@selected_article).each do |text|
      Curses.addstr(text)
    end
  end

  def get_results_for(category)
    url = "http://api.moviepilot.com/v4/tags/#{category.to_s}/recent"
    @articles = JSON.parse(open(url).read)["collection"]
    @selected_article = @articles[0]
    @articles
  end

  def open_article(article)
    url = article_url(article)
    `open #{url}`
  end

  def article_url(article)
    id = article["id"]
    "http://www.moviepilot.com/" + id.to_s
  end

  def article_text(article)
    page = Nokogiri::HTML(open(article_url(article)))
    text = []
    page.css("p").each do |p|
      text << (p.text + "\n")
    end
    text
  end

end

display =  Display.new()

display.run

Curses.close_screen