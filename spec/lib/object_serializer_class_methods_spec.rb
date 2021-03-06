# frozen_string_literal: true

require "spec_helper"

describe FastJsonapi::ObjectSerializer do
  include_context "movie class"

  describe "#has_many" do
    subject(:relationship) { serializer.relationships_to_serialize[:roles] }

    before do
      serializer.has_many(*children)
    end

    after do
      serializer.relationships_to_serialize = {}
    end

    context "with namespace" do
      let(:serializer) { AppName::V1::MovieSerializer }
      let(:children) { [:roles] }

      context "with overrides" do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like "returning correct relationship hash",
                        :"AppName::V1::RoleSerializer",
                        :roles_only_ids,
                        :super_role
      end

      context "without overrides" do
        let(:children) { [:roles] }

        it_behaves_like "returning correct relationship hash",
                        :"AppName::V1::RoleSerializer",
                        :role_ids,
                        :role
      end
    end

    context "without namespace" do
      let(:serializer) { MovieSerializer }

      context "with overrides" do
        let(:children) { [:roles, id_method_name: :roles_only_ids, record_type: :super_role] }

        it_behaves_like "returning correct relationship hash",
                        :RoleSerializer,
                        :roles_only_ids,
                        :super_role
      end

      context "without overrides" do
        let(:children) { [:roles] }

        it_behaves_like "returning correct relationship hash",
                        :RoleSerializer,
                        :role_ids,
                        :role
      end
    end
  end

  describe "#has_many with block" do
    before do
      MovieSerializer.has_many :awards do |movie|
        movie.actors.map(&:awards).flatten
      end
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:awards)
    end

    context "awards is not included" do
      subject(:hash) { MovieSerializer.new(movie).serializable_hash }

      it "returns correct hash" do
        expect(hash[:data][:awards].length).to eq(6)
        expect(hash[:data][:awards][0]).to eq(id: 9)
        expect(hash[:data][:awards][-1]).to eq(id: 28)
      end
    end

    context "state is included" do
      subject(:hash) { MovieSerializer.new(movie, include: [:awards]).serializable_hash }

      it "returns correct hash" do
        expect(hash[:data].length).to eq 4
        expect(hash[:data][:awards][0][:id]).to eq 9
        expect(hash[:data][:awards][0][:title]).to eq "Test Award 9"
        expect(hash[:data][:awards][0]).to include(actor: { id: 1 })
        expect(hash[:data][:awards][-1][:id]).to eq 28
        expect(hash[:data][:awards][-1][:title]).to eq "Test Award 28"
        expect(hash[:data][:awards][-1]).to include(actor: { id: 3 })
      end
    end
  end

  describe "#has_many with block and id_method_name" do
    before do
      MovieSerializer.has_many(:awards, id_method_name: :imdb_award_id) do |movie|
        movie.actors.map(&:awards).flatten
      end
    end

    after do
      MovieSerializer.relationships_to_serialize.delete(:awards)
    end

    context "awards is not included" do
      subject(:hash) { MovieSerializer.new(movie).serializable_hash }

      it "returns correct hash where id is obtained from the method specified via `id_method_name`" do
        expected_award_data = movie.actors.map(&:awards).flatten.map { |actor|
          { id: actor.imdb_award_id }
        }
        serialized_award_data = hash[:data][:awards]

        expect(serialized_award_data).to eq(expected_award_data)
      end
    end
  end

  describe "#belongs_to" do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.belongs_to(*parent)
    end

    after do
      MovieSerializer.relationships_to_serialize = {}
    end

    context "with overrides" do
      let(:parent) {
        [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area]
      }

      it_behaves_like "returning correct relationship hash",
                      :MyAreaSerializer,
                      :blah_id,
                      :awesome_area
    end

    context "without overrides" do
      let(:parent) { [:area] }

      it_behaves_like "returning correct relationship hash",
                      :AreaSerializer,
                      :area_id,
                      :area
    end
  end

  describe "#belongs_to with block" do
    before do
      ActorSerializer.belongs_to :state do |actor|
        actor.agency.state
      end
    end

    after do
      ActorSerializer.relationships_to_serialize.delete(:actorc)
    end

    context "state is not included" do
      subject(:hash) { ActorSerializer.new(actor).serializable_hash }

      it "returns correct hash" do
        expect(hash[:data][:state]).to eq(id: 1)
      end
    end

    context "state is included" do
      subject(:hash) { ActorSerializer.new(actor, include: [:state]).serializable_hash }

      it "returns correct hash" do
        expect(hash[:data][:state].length).to eq 3
        expect(hash[:data][:state][:id]).to eq 1
        expect(hash[:data][:state][:name]).to eq "Test State 1"
        expect(hash[:data][:state]).to include(agencies: [{ id: 432 }])
      end
    end
  end

  describe "#has_one" do
    subject(:relationship) { MovieSerializer.relationships_to_serialize[:area] }

    before do
      MovieSerializer.has_one(*partner)
    end

    after do
      MovieSerializer.relationships_to_serialize = {}
    end

    context "with overrides" do
      let(:partner) {
        [:area, id_method_name: :blah_id, record_type: :awesome_area, serializer: :my_area]
      }

      it_behaves_like "returning correct relationship hash",
                      :MyAreaSerializer,
                      :blah_id,
                      :awesome_area
    end

    context "without overrides" do
      let(:partner) { [:area] }

      it_behaves_like "returning correct relationship hash",
                      :AreaSerializer,
                      :area_id,
                      :area
    end
  end

  describe "#set_id" do
    subject(:serializable_hash) { MovieSerializer.new(resource).serializable_hash }

    context "method name" do
      before do
        MovieSerializer.set_id :owner_id
      end

      after do
        MovieSerializer.set_id nil
      end

      context "when one record is given" do
        let(:resource) { movie }

        it "returns correct hash which id equals owner_id" do
          expect(serializable_hash[:data][:id]).to eq movie.owner_id
        end
      end

      context "when an array of records is given" do
        let(:resource) { [movie, movie] }

        it "returns correct hash which id equals owner_id" do
          expect(serializable_hash[:data][0][:id]).to eq movie.owner_id
          expect(serializable_hash[:data][1][:id]).to eq movie.owner_id
        end
      end
    end

    context "with block" do
      before do
        MovieSerializer.set_id { |record| "movie-#{record.owner_id}" }
      end

      after do
        MovieSerializer.set_id nil
      end

      context "when one record is given" do
        let(:resource) { movie }

        it "returns correct hash which id equals movie-id" do
          expect(serializable_hash[:data][:id]).to eq "movie-#{movie.owner_id}"
        end
      end

      context "when an array of records is given" do
        let(:resource) { [movie, movie] }

        it "returns correct hash which id equals movie-id" do
          expect(serializable_hash[:data][0][:id]).to eq "movie-#{movie.owner_id}"
          expect(serializable_hash[:data][1][:id]).to eq "movie-#{movie.owner_id}"
        end
      end
    end
  end

  describe "#attribute" do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    context "with block" do
      before do
        movie.release_year = 2008
        MovieSerializer.attribute :title_with_year do |record|
          "#{record.name} (#{record.release_year})"
        end
      end

      after do
        MovieSerializer.attributes_to_serialize.delete(:title_with_year)
      end

      it "returns correct hash when serializable_hash is called" do
        expect(serializable_hash[:data][:name]).to eq movie.name
        expect(serializable_hash[:data][:title_with_year]).to(
          eq "#{movie.name} (#{movie.release_year})"
        )
      end
    end

    context "with &:proc" do
      before do
        movie.release_year = 2008
        MovieSerializer.attribute :released_in_year, &:release_year
        MovieSerializer.attribute :name, &:local_name
      end

      after do
        MovieSerializer.attributes_to_serialize.delete(:released_in_year)
      end

      it "returns correct hash when serializable_hash is called" do
        expect(serializable_hash[:data][:name]).to eq "english #{movie.name}"
        expect(serializable_hash[:data][:released_in_year]).to eq movie.release_year
      end
    end
  end

  describe "#meta" do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    before do
      movie.release_year = 2008
      MovieSerializer.meta do |movie|
        {
          years_since_release: year_since_release_calculator(movie.release_year)
        }
      end
    end

    after do
      movie.release_year = nil
      MovieSerializer.meta_to_serialize = nil
    end

    it "returns correct hash when serializable_hash is called" do
      expect(serializable_hash[:data][:meta]).to eq(
        years_since_release: year_since_release_calculator(movie.release_year)
      )
    end

    private

    def year_since_release_calculator(release_year)
      Date.current.year - release_year
    end
  end

  describe "#link" do
    subject(:serializable_hash) { MovieSerializer.new(movie).serializable_hash }

    after do
      MovieSerializer.data_links = {}
      ActorSerializer.data_links = {}
    end

    context "with block calling instance method on serializer" do
      before do
        MovieSerializer.link(:self) { |movie_object| movie_object.url } # rubocop:disable Style/SymbolProc
      end

      let(:url) { "http://movies.com/#{movie.id}" }

      it "returns correct hash when serializable_hash is called" do
        expect(serializable_hash[:data][:self]).to eq url
      end
    end

    context "with block and param" do
      before do
        MovieSerializer.link(:public_url) do |movie_object|
          "http://movies.com/#{movie_object.id}"
        end
      end
      let(:url) { "http://movies.com/#{movie.id}" }

      it "returns correct hash when serializable_hash is called" do
        expect(serializable_hash[:data][:public_url]).to eq url
      end
    end

    context "with method" do
      before do
        MovieSerializer.link(:object_id, :id)
      end

      it "returns correct hash when serializable_hash is called" do
        expect(serializable_hash[:data][:object_id]).to eq movie.id
      end
    end

    context "with method and convention" do
      before do
        MovieSerializer.link(:url)
      end

      it "returns correct hash when serializable_hash is called" do
        expect(serializable_hash[:data][:url]).to eq movie.url
      end
    end

    context "when inheriting from a parent serializer" do
      before do
        MovieSerializer.link(:url) do |movie_object|
          "http://movies.com/#{movie_object.id}"
        end
      end
      subject(:action_serializable_hash) { ActionMovieSerializer.new(movie).serializable_hash }
      subject(:horror_serializable_hash) { HorrorMovieSerializer.new(movie).serializable_hash }

      let(:url) { "http://movies.com/#{movie.id}" }

      it "returns the link for the correct sub-class" do
        expect(action_serializable_hash[:data][:url]).to eq "/action-movie/#{movie.id}"
      end
    end
  end

  describe "#key_transform" do
    subject(:hash) {
      movie_serializer_class.new([movie, movie], include: [:movie_type]).serializable_hash
    }

    let(:movie_serializer_class) { "#{key_transform}_movie_serializer".classify.constantize }

    before(:context) do
      %i[dash camel camel_lower underscore].each do |key_transform|
        movie_serializer_name = "#{key_transform}_movie_serializer".classify
        movie_type_serializer_name = "#{key_transform}_movie_type_serializer".classify
        # https://stackoverflow.com/questions/4113479/dynamic-class-definition-with-a-class-name
        movie_serializer_class = Object.const_set(movie_serializer_name, Class.new)
        # https://rubymonk.com/learning/books/5-metaprogramming-ruby-ascent/chapters/24-eval/lessons/67-instance-eval
        movie_serializer_class.instance_eval do
          include FastJsonapi::ObjectSerializer
          set_type :movie
          set_key_transform key_transform
          attributes :name, :release_year
          has_many :actors
          belongs_to :owner, record_type: :user
          belongs_to :movie_type, serializer: "#{key_transform}_movie_type".to_sym
        end
        movie_type_serializer_class = Object.const_set(movie_type_serializer_name, Class.new)
        movie_type_serializer_class.instance_eval do
          include FastJsonapi::ObjectSerializer
          set_key_transform key_transform
          attributes :name
        end
      end
    end

    context "when key_transform is dash" do
      let(:key_transform) { :dash }

      it_behaves_like "returning key transformed hash",
                      :"movie-type",
                      :"dash-movie-type",
                      :"release-year"
    end

    context "when key_transform is camel" do
      let(:key_transform) { :camel }

      it_behaves_like "returning key transformed hash",
                      :MovieType,
                      :CamelMovieType,
                      :ReleaseYear
    end

    context "when key_transform is camel_lower" do
      let(:key_transform) { :camel_lower }

      it_behaves_like "returning key transformed hash",
                      :movieType,
                      :camelLowerMovieType,
                      :releaseYear
    end

    context "when key_transform is underscore" do
      let(:key_transform) { :underscore }

      it_behaves_like "returning key transformed hash",
                      :movie_type,
                      :underscore_movie_type,
                      :release_year
    end
  end
end
