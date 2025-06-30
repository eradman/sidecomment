require_relative 'chromium'

# Run actions in a real browser instance
class ClientTest < Minitest::Test
  def setup
    @@tab ||= Chromium.browser
    tab = @@tab
    tab.playback_rate = 10
    tab.options.logger.truncate
  end

  def teardown
    @@tab.reset
  end

  def test_start_comment
    tab = @@tab
    url = "file://#{__dir__}/page1.html"
    tab.go_to(url)

    heading = tab.css('h2')[0]
    x, y = heading.find_position
    tab.mouse.click x: x, y: y, count: 3
    sleep 0.5
    tab.at_css('#sidecomment_btn_show').click
    tab.at_css('#sidecomment_commentcode').focus.type('fmKmGEhDVxM', :Tab)
    tab.at_css('#sidecomment_comment_area').focus.type('A comment', :Enter)
    tab.at_css('#sidecomment_btn_close').click
    refute tab.options.logger.exceptions.pop
  end

  def test_hint_mouseover
    tab = @@tab
    url = "file://#{__dir__}/page1.html"
    tab.go_to(url)

    tab.css('p').each do |p|
      x, y = p.find_position
      tab.mouse.move x: x, y: y
      sleep 0.1
    end
    refute tab.options.logger.exceptions.pop
  end
end
