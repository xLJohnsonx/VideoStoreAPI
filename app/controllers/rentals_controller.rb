class RentalsController < ApplicationController
  before_action :get_query_params, only: [:overdue]

  def zomg
    render json: {message: "it works"}
  end

  def check_out
    @rental = Rental.new(rental_params)
    unless @rental.checkout_data && @rental.save
      render json: {ok: false, cause: "validation errors", errors: @rental.errors.messages}, status: :bad_request
    end
  end

  def check_in
    @rental = Rental.find_by(movie_id: params[:movie_id], customer_id: params[:customer_id], checkin_date: nil)
    unless @rental.checkin_data && @rental.save
      render json: {ok: false, cause: "validation errors", errors: @rental.errors.messages}, status: :bad_request
    end
  end

  def overdue
    overdue_rentals = Rental.includes(:movie).includes(:customer).where(checkin_date: nil).where("rentals.due_date < ?", Date.current)

    # @sorters will always be a 1-d ordered array of unique values.
    @sorters.each do |sorter|
      if sorter == "checkout_date" || sorter == "due_date"
        overdue_rentals = overdue_rentals.order(sorter => :asc) # asc is default - just being explicit
      elsif sorter == "title"
        overdue_rentals = overdue_rentals.order("movies.title asc") 
      elsif sorter == "name"
        overdue_rentals = overdue_rentals.order("customers.name asc")
      end
    end
    @overdue_rentals = overdue_rentals
  end

  private

  def rental_params
     return params.permit(:customer_id, :movie_id)
  end

end
