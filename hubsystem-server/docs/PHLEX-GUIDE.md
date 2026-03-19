# Phlex Guide for HubSystem

Quick reference for building UI components with [Phlex](https://www.phlex.fun) in this project. Phlex replaces ERB with pure Ruby components.

## Core Concepts

### Components

Every component inherits from `Phlex::HTML` and implements `view_template`:

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
class Table < Phlex::HTML
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

A Kit is a module that lets you render components with a method-call syntax instead of `render ComponentClass.new(...)`.

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

Three approaches, from simplest to most flexible:

### 1. Composition (recommended for HubSystem)

```ruby
class Views::Articles::Index < Views::Base
  def view_template
    render Components::Layout.new(title: "Articles") do
      h1 { "Articles" }
    end
  end
end
```

Set `layout false` in the controller.

### 2. Inheritance via `around_template`

```ruby
class Views::Base < Phlex::HTML
  def around_template
    doctype
    html do
      head { title { page_title } }
      body { super }
    end
  end

  def page_title = "HubSystem"
end
```

Subclasses override `view_template` and optionally `page_title`.

### 3. Legacy Rails layout integration

```ruby
class Components::Layout < Components::Base
  include Phlex::Rails::Layout
end

# In controller:
layout { Components::Layout }
```

## Rails Helpers

**Never** `include` Rails helper modules directly — they can override core Phlex methods.

### Route helpers (most common)

```ruby
class Components::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
end
```

### Custom helpers

```ruby
class Components::Base < Phlex::HTML
  register_value_helper :format_date     # returns a value
  register_output_helper :pagy_nav       # returns safe HTML
end
```

Prefer converting helpers into Phlex components or plain methods on your base component.

## Literal Properties (Type-Safe Props)

Reduces initializer boilerplate with typed, defaulted properties:

```ruby
class Components::Base < Phlex::HTML
  extend Literal::Properties
end

class Components::Button < Components::Base
  Size = _Union(:sm, :md, :lg)
  Variant = _Union(:primary, :secondary, :danger, :ghost)

  prop :label, String
  prop :size, Size, default: :md
  prop :variant, Variant, default: :primary
  prop :disabled, _Boolean, default: false

  def view_template
    button(class: "btn btn-#{@variant} btn-#{@size}", disabled: @disabled) { @label }
  end
end
```

## Testing

Phlex components are plain Ruby objects. Test them by calling `.call`:

```ruby
# Simple assertion
output = Components::Card.new(title: "Test").call
assert_equal '<article class="card"><h2>Test</h2></article>', output

# With Nokogiri for complex HTML
fragment = Nokogiri::HTML5.fragment(output)
assert fragment.at_css("h2")&.text == "Test"
```

### Rails integration in tests

```ruby
module ComponentTestHelper
  def render(...)
    view_context.render(...)
  end

  def view_context
    controller.view_context
  end

  def controller
    @controller ||= ActionView::TestCase::TestController.new
  end
end
```

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
