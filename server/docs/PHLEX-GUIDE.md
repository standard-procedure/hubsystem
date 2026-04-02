# Phlex Guide for HubSystem

Quick reference for building UI components with [Phlex](https://www.phlex.fun) in this project. Phlex replaces ERB with pure Ruby components.

## Core Concepts

### Components

Every component inherits from `Phlex::HTML` and implements `view_template` - there is a [base class](app/components/base.rb) defined:

```ruby
class Components::Card < Phlex::HTML
  def initialize(title:)
    @title = title
  end

  def view_template
    article(class: "card") do
      h2 { @title }
      yield  # renders the block passed by the caller
    end
  end
end
```

### Rendering

**From a Rails controller:**
```ruby
class ArticlesController < ApplicationController
  def index
    render Views::Articles::Index.new(articles: Article.all)
  end
end
```

**From another component:**
```ruby
def view_template
  @articles.each do |article|
    render Components::Card.new(title: article.title) do
      p { article.body }
    end
  end
end
```

Parameterless components can be rendered by class: `render Components::Footer`.

### Views vs Components

A **view** is a root-level component (rendered by a controller). It typically starts with `doctype` and ends with `</html>`. A **component** is rendered inside other components or views.

Generate a view: `bundle exec rails g phlex:view Articles::Index`

## HTML Elements

Every HTML element has a corresponding Ruby method. Content goes in blocks:

```ruby
div(class: "wrapper") do
  h1 { "Title" }
  p { "Body text" }
  input(type: "text", placeholder: "Name...")  # void element, no block
end
```

### Custom Elements (Web Components)

```ruby
class MyView < Phlex::HTML
  register_element :trix_editor  # renders as <trix-editor>
end
```

### SVG

The `svg` element yields a `Phlex::SVG` instance:

```ruby
svg do |s|
  s.rect(x: 10, y: 10, width: 100, height: 100)
end
```

## Attributes

Attributes are keyword arguments. Phlex converts underscores to dashes automatically.

```ruby
h1(data_controller: "hello")  # => <h1 data-controller="hello">
```

| Value type | Behaviour |
|---|---|
| `String` | Rendered as-is (quotes escaped) |
| `Symbol` | Underscores converted to dashes |
| `true` | Valueless boolean attribute: `<textarea disabled>` |
| `false` / `nil` | Attribute omitted entirely |
| `Array` / `Set` | Compacted + joined with spaces (great for conditional classes) |
| `Hash` | Nested with dash separators: `data: { id: 1 }` => `data-id="1"` |

### Classes (conditional)

```ruby
div(class: ["btn", ("active" if @active), ("disabled" if @disabled)])
```

### Style (hash form)

```ruby
div(style: { color: "red", font_size: "16px" })
# => <div style="color: red; font-size: 16px;">
```

### Security

Event attributes (`onclick`, etc.) are blocked. `href` blocks `javascript:` URLs. Use `safe()` to bypass when you know the value is trusted.

## Yielding & Composition

### Basic content yield

```ruby
class Card < Phlex::HTML
  def view_template(&content)
    article(class: "card", &content)
  end
end
```

### Yielding an interface

Components yield `self`, so callers can invoke public methods:

```ruby
# Usage
render Nav do |nav|
  nav.item("/") { "Home" }
  nav.divider
  nav.item("/about") { "About" }
end

# Implementation
class Nav < Phlex::HTML
  def view_template(&)
    nav(class: "nav", &)
  end

  def item(href, &)
    a(href:, class: "nav-item", &)
  end

  def divider
    span(class: "nav-divider")
  end
end
```

### `vanish` — collect config before rendering

`vanish(&)` yields a block but discards its HTML output. Useful for declarative APIs:

```ruby
class Table < Components::Base
  def initialize(rows)
    @rows = rows
    @columns = []
  end

  def view_template(&)
    vanish(&)

    table do
      thead { tr { @columns.each { |c| th { c[:header] } } } }
      tbody do
        @rows.each do |row|
          tr { @columns.each { |c| td { c[:block].call(row) } } }
        end
      end
    end
  end

  def column(header, &block)
    @columns << { header:, block: }
  end
end
```

## Kits

A Kit is a module that lets you render components with a method-call syntax instead of `render ComponentClass.new(...)`.  This is configured in the [initialiser](config/initializers/phlex.rb).  This also includes several Phlex::Rails helpers.  

```ruby
module Components
  extend Phlex::Kit
end

# Now inside any component that includes Components:
Card("Hello") { p { "content" } }
# equivalent to: render Components::Card.new("Hello") { p { "content" } }
```

Kits do **not** work from ERB templates.

## Layouts

Layouts are handled using composition, with a pre-defined [default layout](app/views/layouts/application.rb)

```ruby
class Views::Articles::Index < Views::Base
  def view_template
    render Components::Layout.new(title: "Articles") do
      h1 { "Articles" }
    end
  end
end
```

`layout false` is set in the [base controller](app/controllers/application_controller.rb).

## Rails Helpers

**Never** `include` Rails helper modules directly — they can override core Phlex methods.  Instead use `include Phlex::Rails::Helpers::HELPER_NAME` (for example, FormWith for the `form_with` helper).

### Base Component

Route Helpers and `dom_id` are automatically included in the [base class](app/components/base.rb), as are several common Rails helper modules.  

### Custom helpers

```ruby
class Components::Base < Phlex::HTML
  register_value_helper :format_date     # returns a value
  register_output_helper :pagy_nav       # returns safe HTML
end
```

Prefer converting helpers into Phlex components or plain methods on your base component.

## Literal Properties (Type-Safe Props)

Reduces initialiser boilerplate with typed, defaulted properties.  Creates instance variables for each property, checks the type on initialisation and catches typos when accessing instance variables (`@nmae` will raise an error if the prop was called `@name`).

The module is included in the [base class](app/components/base.rb), with a rich set of [in-built types](https://literal.fun/docs/built-in-types.html), plus extensions also included in the [Types module](app/components/types.rb).

```ruby
class Components::Button < Components::Base
  # Enum is an extended type
  Size = OneOf(:sm, :md, :lg)
  Variant = OneOf(:primary, :secondary, :danger, :ghost)

  prop :label, String
  prop :size, Size, default: :md
  prop :variant, Variant, default: :primary
  prop :disabled, _Boolean, default: false
  prop :description, _String? # nilable

  def view_template
    button(class: "btn btn-#{@variant} btn-#{@size}", disabled: @disabled) { @label }
  end
end
```

## Testing

Specs live in `spec/components/` and use RSpec. Components that use Rails route helpers need a view context — use `view_context.render(...)` to render them.

### Test helper pattern

Define these helpers in your spec (or extract to a shared module):

```ruby
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
```

### Writing specs

Use `render_fragment` to get a Nokogiri fragment, then query with CSS selectors:

```ruby
RSpec.describe Components::CrtMonitor, type: :component do
  fixtures :users

  # ... helper methods above ...

  it "renders the brand name" do
    html = render_fragment(described_class.new(brand: "TestBrand"))

    expect(html.at_css(".crt-brand").text).to eq("TestBrand")
  end

  it "renders a logout link when a user is set" do
    html = render_fragment(described_class.new(user: users(:alice)))
    badge = html.at_css("a.crt-badge")

    expect(badge).to be_present
    expect(badge["href"]).to eq("/logout")
  end
end
```

### Simple components (no Rails helpers)

Components that don't use route helpers or other Rails view helpers can be tested with `.call` directly:

```ruby
output = Components::Card.new(title: "Test").call
fragment = Nokogiri::HTML5.fragment(output)
expect(fragment.at_css("h2").text).to eq("Test")
```

### Tips

- Use `at_css` for single elements, `css` for collections
- Check element names with `.name` (e.g. `expect(node.name).to eq("a")`)
- Check attributes with `node["href"]`, `node["class"]`, `node["title"]`
- Use `include` matcher for class checks: `expect(node["class"]).to include("active")`
- Fixtures are loaded with `fixtures :users` — see `spec/fixtures/`

## Helpers Reference

| Helper | Purpose |
|---|---|
| `mix(hash1, hash2, ...)` | Merge attribute hashes, concatenating classes instead of replacing |
| `mix({ class: "a" }, { class!: "b" })` | Bang (`!`) to force-override instead of merge |
| `grab(class:)` | Extract keyword args that are Ruby reserved words |
| `plain(text)` | Output plain text (no element wrapper) |
| `comment { "..." }` | HTML comment |
| `whitespace` | Explicit whitespace between inline elements |
| `safe(value)` | Mark a string as safe (bypasses security checks) |

## File Organisation in HubSystem

```
app/
  components/          # Reusable UI components
    base.rb            # Components::Base < Phlex::HTML
    layout.rb          # Main application layout
    card.rb
    ...
  views/               # Controller-rendered views
    base.rb            # Views::Base (may inherit layout)
    articles/
      index.rb
      show.rb
```
