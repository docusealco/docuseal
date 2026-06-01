# Preventing FOUC (Flash of Unstyled Content)

## Overview

FOUC (Flash of Unstyled Content) occurs when content is rendered before stylesheets load, causing a brief flash of unstyled content. This guide explains how to prevent FOUC when using Shakapacker's view helpers.

## Basic Solution

Place `stylesheet_pack_tag` in the `<head>` section of your layout, not at the bottom of the `<body>`. This ensures styles load before content is rendered.

**Recommended layout structure:**

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My App</title>

  <%= stylesheet_pack_tag 'application', media: 'all' %>
  <%= javascript_pack_tag 'application', defer: true %>
</head>
<body>
  <%= yield %>
</body>
</html>
```

## Advanced: Using `content_for` with Dynamic Pack Loading

If you're using libraries that dynamically append packs during rendering (like React on Rails with `auto_load_bundle`), or if you need to append packs from views/partials, you must ensure that all `append_*` helpers execute before the pack tags render.

Rails' `content_for` pattern solves this execution order problem.

### The `content_for :body_content` Pattern

This pattern renders the body content first, allowing all append calls to register before the pack tags in the head are rendered:

```erb
<% content_for :body_content do %>
  <%= render 'shared/header' %>
  <%= yield %>
  <%= render 'shared/footer' %>
<% end %>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My App</title>

  <%= stylesheet_pack_tag 'application', media: 'all' %>
  <%= javascript_pack_tag 'application', defer: true %>
</head>
<body>
  <%= yield :body_content %>
</body>
</html>
```

**How this works:**

1. The `content_for :body_content` block executes first during template rendering
2. Any `append_stylesheet_pack_tag` or `append_javascript_pack_tag` calls in your views/partials register their packs
3. Libraries like React on Rails can auto-append component-specific packs during rendering
4. The pack tags in `<head>` then render with all registered appends
5. Finally, `yield :body_content` outputs the pre-rendered content

**Result:**

- ✅ All appends (explicit + auto) happen before pack tags
- ✅ Stylesheets load in head, eliminating FOUC
- ✅ Works with `auto_load_bundle` and similar features

### Alternative: Using `yield :head` for Explicit Appends

For simpler cases where you know which packs you need upfront and can explicitly specify them, you can use `content_for :head` in your views and yield it in your layout.

**Layout (app/views/layouts/application.html.erb):**

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My App</title>

  <%= yield :head %>
  <%= stylesheet_pack_tag 'application', media: 'all' %>
  <%= javascript_pack_tag 'application', defer: true %>
</head>
<body>
  <%= yield %>
</body>
</html>
```

**View (app/views/pages/show.html.erb):**

```erb
<% content_for :head do %>
  <%= append_stylesheet_pack_tag 'my-component' %>
  <%= append_javascript_pack_tag 'my-component' %>
<% end %>

<h1>My Page</h1>
<p>Content goes here...</p>
```

This approach works when:

- You're not using auto-appending libraries
- You can explicitly list all required packs in each view
- You don't need dynamic pack determination

## Key Takeaways

- Always place `stylesheet_pack_tag` in `<head>` to prevent FOUC
- Use `content_for` to control execution order when using `append_*` helpers
- Ensure `append_*` helpers execute before the main pack tags
- JavaScript can use `defer: true` (default) or be placed at end of `<body>`
- The `content_for :body_content` pattern is essential when using auto-appending libraries

## Related

- [View Helpers Documentation](../README.md#view-helpers)
- [Troubleshooting Guide](./troubleshooting.md)
- Original issue: [#720](https://github.com/shakacode/shakapacker/issues/720)
- Working implementation: [react-webpack-rails-tutorial PR #686](https://github.com/shakacode/react-webpack-rails-tutorial/pull/686)
