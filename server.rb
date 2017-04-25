require "sinatra"
require "pg"
require 'pry'

set :bind, '0.0.0.0'  # bind to all interfaces

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end


get "/actors" do

  @actors = db_connection { |conn| conn.exec("SELECT actors.id, actors.name, COUNT(movies) AS count FROM cast_members
  RIGHT JOIN movies ON cast_members.movie_id = movies.id
  RIGHT JOIN actors ON cast_members.actor_id = actors.id
  GROUP BY actors.id ORDER BY actors.name ASC") }
  erb :'actors/index'

end




get "/actors/:id" do
  @actor_id = params[:id]

  @actor_info = db_connection { |conn| conn.exec("SELECT movies.title, actors.name, movies.id, cast_members.character AS role
    FROM cast_members
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.id = '#{@actor_id}'") }


erb :'actors/show'

end

post "/actors" do

  query = params['query']
  @actors = db_connection { |conn| conn.exec("SELECT actors.id, actors.name, cast_members.character
    FROM cast_members
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN actors ON cast_members.actor_id = actors.id
     WHERE name LIKE '%#{query}%' OR cast_members.character LIKE '%#{query}%'") }
  erb :'actors/index'

end

get "/movies" do
  if params == {"order"=>"year"}
    @movies = db_connection { |conn| conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.year ASC") }
    erb :'movies/index'
  elsif
    params == {"order"=>"rating"}
    @movies = db_connection { |conn| conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.rating ASC") }
    erb :'movies/index'
  else
    @movies = db_connection { |conn| conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.title ASC") }
    erb :'movies/index'
  end
end




post "/movies" do

  query = params['query']
  @movies = db_connection { |conn| conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating, movies.synopsis, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    WHERE movies.title LIKE '%#{query}%'") }
  erb :'movies/index'
end


get "/movies/:id" do

  @movie_id = params[:id]
  @movie_info = db_connection { |conn| conn.exec("SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, actors.name, actors.id, cast_members.character AS role
    FROM cast_members
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN actors ON cast_members.actor_id = actors.id
    JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = '#{@movie_id}'") }

  erb :'movies/show'

end
