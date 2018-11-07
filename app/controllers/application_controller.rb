class ApplicationController < ActionController::API
require 'cgi'
private

# Any endpoint that returns a list should accept 3 optional query parameters:
  def get_query_params
    @sorters = permit_sort_params
    @per_page = permit_p_param
    @num_pages = permit_n_param
  end

  def permit_sort_params
    return [:id] unless params[:sort]
    # returns an array of 1+ sort fields (string) that are valid for the model.
    # different controllers accept different sort fields.
    valid_sorters = {
                      'customers' => %w(name registered_at postal_code),
                      'movies' => %w(title release_date),
                      'rentals' => %w(title name checkout_date due_date) # Just For Overdue Rentals
                    }
    sorters = CGI.parse(request.query_string)["sort"].uniq
    sorters = sorters.select { |sorter| valid_sorters[controller_name].include?(sorter) }

    return sorters.empty? ? ["id"] : sorters # The default sorter is "id"
  end

  def permit_p_param
    # return 1 integer (see wp gem)
  end

  def permit_n_param
    # return 1 integer (see wp gem)
  end


end

# CGI.parse knows what to do if a query param appears > once in the url.
# it just adds it to the array!
# url    = 'http://www.foo.com?id=4&empid=6'
# uri    = URI.parse(url)
# params = CGI.parse(uri.query)
# params is now {"id"=>["4"], "empid"=>["6"]}
#
# Any endpoint that returns a list should accept 3 optional query parameters:
#
# Name	Value	Description
# sort	string	Sort objects by this field, in ascending order
# n	integer	Number of responses to return per page
# p	integer	Page of responses to return
# So, for an API endpoint like GET /customers, the following requests should be valid:
#
# GET /customers: All customers, sorted by ID
# GET /customers?sort=name: All customers, sorted by name
# GET /customers?n=10&p=2: Customers 10-19, sorted by ID
# GET /customers?sort=name&n=10&p=2: Customers 10-19, sorted by name
# Of course, adding new features means you should be adding new controller tests to verify them.
#
# Things to note:
#
# Sorting by ID is the rails default
# Possible sort fields:
# Customers can be sorted by name, registered_at and postal_code
# Movies can be sorted by title and release_date
# Overdue rentals can be sorted by title, name, checkout_date and due_date
# If the client requests both sorting and pagination, pagination should be relative to the sorted order
# Check out the will_paginate gem
