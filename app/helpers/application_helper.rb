module ApplicationHelper
  include Pagy::Frontend

  def highlight_search_term(text, query)
    return text if query.blank?

    sanitize(text.to_s.gsub(/(#{Regexp.escape(query)})/i, '<mark class="bg-yellow-200">\1</mark>').html_safe)
  end
end
