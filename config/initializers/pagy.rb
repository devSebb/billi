# Load the Pagy Nav frontend
require "pagy/extras/bootstrap"
require "pagy/extras/navs"

# Default items per page
Pagy::DEFAULT[:items] = 10

# Navigation bar sizing
Pagy::DEFAULT[:size] = [ 1, 4, 4, 1 ]

# Add nav styling
Pagy::DEFAULT[:nav_aria_label] = "Pagination"

# Custom nav styling
class Pagy
  DEFAULT.merge!(
    nav_html: '<nav class="pagy-nav pagination" aria-label="pager"><span class="page">%{link}</span></nav>',
    nav_link_html: '<a href="%{href}" class="text-black hover:text-gray-600 px-3 py-2 rounded-lg %{active_class}">%{text}</a>',
    nav_item_html: '<span class="text-black px-3 py-2">%{text}</span>',
    gap_marker: '<span class="text-black px-3 py-2">...</span>',
    active_class: "bg-gray-100 font-semibold"
  )
end

# Freeze the hash after all configurations are set
Pagy::DEFAULT.freeze
