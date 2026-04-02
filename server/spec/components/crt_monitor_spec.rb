# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::CrtMonitor, type: :component do
  fixtures :users

  def controller
    @controller ||= ActionView::TestCase::TestController.new
  end

  def view_context
    controller.view_context
  end

  def render(component, &block)
    view_context.render(component, &block)
  end

  def render_fragment(component, &block)
    Nokogiri::HTML5.fragment(render(component, &block))
  end

  describe "structure" do
    it "renders the CRT housing with top, bezel, and bottom sections" do
      html = render_fragment(described_class.new)

      expect(html.at_css(".crt-housing")).to be_present
      expect(html.at_css(".crt-top")).to be_present
      expect(html.at_css(".crt-bezel")).to be_present
      expect(html.at_css(".crt-bottom")).to be_present
    end

    it "renders content inside the screen" do
      html = render_fragment(described_class.new) { "<p>Hello</p>" }

      expect(html.at_css(".screen-content")).to be_present
    end

    it "renders the title as a link to root" do
      html = render_fragment(described_class.new(title: "TestTitle"))

      brand = html.at_css(".crt-brand")
      expect(brand.text).to eq("TestTitle")
      expect(brand.name).to eq("a")
      expect(brand["href"]).to eq("/")
    end

    it "defaults the title to HubSystem" do
      html = render_fragment(described_class.new)

      expect(html.at_css(".crt-brand").text).to eq("HubSystem")
    end

    it "renders a back arrow when return_href is provided" do
      html = render_fragment(described_class.new(return_href: "/users"))

      back = html.at_css(".crt-back")
      expect(back).to be_present
      expect(back["href"]).to eq("/users")
    end

    it "does not render a back arrow by default" do
      html = render_fragment(described_class.new)

      expect(html.at_css(".crt-back")).to be_nil
    end

    it "renders vents" do
      html = render_fragment(described_class.new)

      expect(html.css(".crt-vent").length).to eq(12)
    end

    it "renders the nameplate" do
      html = render_fragment(described_class.new)

      expect(html.at_css(".crt-nameplate-text").text).to eq("MU/TH/UR 6000")
    end
  end

  describe "power button" do
    it "does not render the power badge when no user is set" do
      html = render_fragment(described_class.new)

      expect(html.at_css(".crt-badge")).not_to be_present
    end

    it "renders the power badge as a logout link when a user is set" do
      html = render_fragment(described_class.new(user: users(:alice)))
      badge = html.at_css("a.crt-badge")

      expect(badge).to be_present
      expect(badge["href"]).to eq("/logout")
      expect(badge.at_css(".crt-badge-led")).to be_present
      expect(badge.at_css(".crt-badge-text").text).to eq(I18n.t("application.logout"))
    end
  end

  describe "navigation buttons" do
    it "renders one button per navigation location" do
      html = render_fragment(described_class.new)

      expect(html.css(".crt-controls .crt-button").length).to eq(Components::MainNavigation::LOCATIONS.size)
    end

    it "renders all navigation labels as button titles" do
      html = render_fragment(described_class.new)
      titles = html.css(".crt-controls .crt-button").map { |b| b["title"] }

      expect(titles).to eq(["Dashboard", "Messages", "Projects", "Terminals", "Settings"])
    end

    it "renders the dashboard button as the first link pointing to root" do
      html = render_fragment(described_class.new)
      first = html.css(".crt-controls .crt-button").first

      expect(first.name).to eq("a")
      expect(first["title"]).to eq("Dashboard")
      expect(first["href"]).to eq("/")
    end

    it "marks the dashboard button as active by default" do
      html = render_fragment(described_class.new)
      buttons = html.css(".crt-controls .crt-button")

      expect(buttons[0]["class"]).to include("crt-button--active")
      expect(buttons[1]["class"]).not_to include("crt-button--active")
    end

    it "marks the specified button as active" do
      html = render_fragment(described_class.new(active: :messages))
      buttons = html.css(".crt-controls .crt-button")

      expect(buttons[0]["class"]).not_to include("crt-button--active")
      expect(buttons[1]["class"]).to include("crt-button--active")
    end

    it "marks specified buttons as alerts" do
      html = render_fragment(described_class.new(alerts: [:messages]))
      buttons = html.css(".crt-controls .crt-button")

      expect(buttons[1]["class"]).to include("crt-button--alert")
      expect(buttons[0]["class"]).not_to include("crt-button--alert")
    end
  end
end
