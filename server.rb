require "sinatra"
require "pg"
require "pry"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

system 'psql movies < schema.sql'

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/actors/:id" do
  id = params["id"]

  movie_id = ""
  @actors_movies_characters = ""
  db_connection do |conn|

      query = %(SELECT actors.name, cast_members.movie_id, cast_members.character
        FROM actors
        JOIN cast_members ON actors.id = cast_members.actor_id
        WHERE actors.id = ($1)
        )
      @actors_movies_characters = conn.exec(query, [id])
      # binding.pry
      movie_id = @actors_movies_characters[0]["movie_id"]

      query1 = %(SELECT movies.title, movies.id, cast_members.character
        FROM movies
        JOIN cast_members ON cast_members.movie_id = movies.id
        WHERE movies.id = ($1)
      )
      @movies_w_id = conn.exec(query1, [movie_id])
  end

  erb :"actors/show"

end

get '/movies' do
  @movies_w_gen_stud = ""

  db_connection do |conn|
      query = %(SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS movie_genre, studios.name AS movie_studio
        FROM movies
        LEFT JOIN genres ON movies.genre_id = genres.id
        LEFT JOIN studios ON movies.studio_id = studios.id
      )

      @movies_w_gen_stud = conn.exec(query)
  end

  erb :'/movies/index'
end

# Visiting /movies/:id will show the details for the movie.
# This page should contain information about the movie (including genre and studio)
# as well as a list of all of the actors and their roles.
# Each actor name is a link to the details page for that actor.
get '/movies/:id' do
  movie_id = params["id"]
  @movies = ""

  db_connection do |conn|
    query = %(SELECT movies.title, movies.year, movies.rating, genres.name AS movie_genre,
      studios.name AS movie_studio, cast_members.character, actors.name AS actor_name, actors.id AS actor_id
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      LEFT JOIN cast_members ON cast_members.movie_id= movies.id
      LEFT JOIN actors ON actors.id = cast_members.actor_id
      WHERE movies.id = ($1)
    )

    @movies = conn.exec(query, [movie_id])
  end


  erb :'/movies/show'
end


get "/actors" do
  @actors  = ""

  db_connection do |conn|
    @actors = conn.exec("SELECT name, id FROM actors ORDER BY name ASC")
  end

  erb :'actors/index'
end
