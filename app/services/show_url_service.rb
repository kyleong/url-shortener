class ShowUrlService < ApplicationService
  PER_PAGE = 5

  def initialize(url, page)
    @url = url
    @page = page.to_i <= 0 ? 1 : page.to_i
  end

  def call
    offset = (@page - 1) * PER_PAGE

    visits = @url.visits
    .order(created_at: :desc)
    .limit(PER_PAGE)
    .offset(offset)

    total_visits = @url.visits.count
    next_page = total_visits > @page * PER_PAGE ? @page + 1 : nil

    [ visits, next_page ]
  end
end
