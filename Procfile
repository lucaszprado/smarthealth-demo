# web dyno runs your Puma server on the port Heroku assigns via $PORT.
web: bundle exec rails server -p $PORT

# worker dyno runs your Solid Queue background processor
worker: bundle exec rails solid_queue:start
