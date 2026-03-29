# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::CrtMonitor, type: :component do
  fixtures :users, :humans, :synthetics, :synthetic_classes

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

    it "renders the brand name" do
      html = render_fragment(described_class.new(brand: "TestBrand"))

      expect(html.at_css(".crt-brand").text).to eq("TestBrand")
    end

    it "defaults the brand to HubSystem" do
      html = render_fragment(described_class.new)

      expect(html.at_css(".crt-brand").text).to eq("HubSystem")
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
      expect(badge.at_css(".crt-badge-text").text).to eq("Power")
    end
  end

  describe "navigation knobs" do
    it "renders three navigation knobs" do
      html = render_fragment(described_class.new)

      expect(html.css(".crt-controls .crt-knob").length).to eq(3)
    end

    it "renders Dashboard and Messages as links" do
      html = render_fragment(described_class.new)
      knobs = html.css(".crt-controls .crt-knob")

      expect(knobs[0].name).to eq("a")
      expect(knobs[0]["title"]).to eq("Dashboard")
      expect(knobs[0]["href"]).to eq("/")

      expect(knobs[1].name).to eq("a")
      expect(knobs[1]["title"]).to eq("Messages")
      expect(knobs[1]["href"]).to eq("/conversations")
    end

    it "renders System as a link to tasks" do
      html = render_fragment(described_class.new)
      knobs = html.css(".crt-controls .crt-knob")

      expect(knobs[2].name).to eq("a")
      expect(knobs[2]["title"]).to eq("System")
      expect(knobs[2]["href"]).to eq("/tasks")
    end

    it "highlights the dashboard knob by default" do
      html = render_fragment(described_class.new)
      knobs = html.css(".crt-controls .crt-knob")

      expect(knobs[0]["class"]).to include("crt-knob--power")
      expect(knobs[1]["class"]).not_to include("crt-knob--power")
      expect(knobs[2]["class"]).not_to include("crt-knob--power")
    end

    it "highlights the messages knob when active_nav is messages" do
      html = render_fragment(described_class.new(active_nav: :messages))
      knobs = html.css(".crt-controls .crt-knob")

      expect(knobs[0]["class"]).not_to include("crt-knob--power")
      expect(knobs[1]["class"]).to include("crt-knob--power")
    end

    it "highlights the system knob when active_nav is system" do
      html = render_fragment(described_class.new(active_nav: :system))
      knobs = html.css(".crt-controls .crt-knob")

      expect(knobs[2]["class"]).to include("crt-knob--power")
    end
  end
end
