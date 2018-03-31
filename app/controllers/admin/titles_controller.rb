module Admin
  class TitlesController < AdminControllerBase
    def index
      titles = Title
        .includes(:functions)
        .select("titles.*, count(inclusions.id) as inclusions_count")
          .joins(compositions: :inclusions)
          .group("titles.id")
        .order(:text)

      @titles = filter_by_letter(titles)

      @functions = Function.order(:name)
    end

    def update
      title = Title.find(params[:id])

      title.assign_attributes(title_params)

      if title.text_changed? && (other_title = Title.find_by(text: title.text))
        title.functions += other_title.functions
        title.compositions += other_title.compositions
        other_title.destroy!
      end

      unless title.save
        errors = title.errors.full_messages
        flash[:error] = errors.to_sentence
      end

      redirect_to admin_titles_path
    end

  private

    def title_params
      params.require(:title).permit(
        :text,
        function_ids: [],
      )
    end

    def current_letter
      params[:letter] || special_character
    end
    helper_method :current_letter

    def letter_options
      @letter_options ||= [special_character].concat(("A".."Z").to_a)
    end
    helper_method :letter_options

    def special_character
      "#"
    end

    def valid_letter?
      current_letter.blank? || letter_options.include?(current_letter)
    end

    def filter_by_letter(titles)
      raise RuntimeError.new("Invalid letter page") unless valid_letter?

      if current_letter == special_character
        titles.where("text ~* '^[^a-z]'")
      else
        titles.where("text ~~* '#{current_letter}%'")
      end
    end
  end
end
