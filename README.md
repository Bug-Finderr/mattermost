# Assignment Submission Doc

## Developer Setup

- Dev setup completed as per the [official Mattermost developer guide](https://developers.mattermost.com/contribute/developer-setup/).

## Bulk Data Generation

- Used a [Python script](tools/gen_bulk_posts.py) to generate 5 million posts via the Mattermost API.
- **To post in a specific channel (recommended):**
  1. Get your team ID: `GET http://localhost:8065/api/v4/users/me/teams`
  2. Get your desired channel ID: `GET http://localhost:8065/api/v4/users/me/teams/{team_id}/channels`
  3. Set `CHANNEL_ID` in the script accordingly.
- **To check the size and row count of the Posts table:**
  1. Get your Postgres container ID: `docker ps | grep postgres`
  2. Run:

     ```zsh
     docker exec -it <container_id> psql -U mmuser -d mattermost_test -c "SELECT pg_size_pretty(pg_total_relation_size('Posts')) AS total_size, COUNT(*) AS row_count FROM Posts;"
     ```

- Time taken: >5 hours (single-threaded) for 3mil posts. Optimized version with threading took ~2hr for 2mil posts.
- Search performance (SQL backend): Fast for simple queries, even at 5M posts. Time wasted!! Anyways...
- Note: Real-world performance may degrade with more complex queries, concurrent users, or less powerful hardware.
- **Ref:** [Elasticsearch is required for deployments with over 5 million posts to avoid significant performance issues](https://docs.mattermost.com/scale/elasticsearch.html#:~:text=For%20deployments%20with%20over%205%20million%20posts%2C%20Elasticsearch%20is%20required%20to%20avoid%20significant%20performance%20issues%20(such%20as%20timeouts)%20with%20search%20and%20at%2Dmentions.)

## Elasticsearch Integration

Enabled Enterprise Elasticsearch features in Team Edition by modifying `server/channels/app/platform/license.go` to inject a fake license and `server/Makefile` to expose UI components.

- **To use the provided configuration for Elasticsearch and Docker services:**
  1. Rename the config files as shown below:

     ```zsh
     # Rename config.copy.json and config.override.copy.mk to their active names
     mv server/config/config.copy.json server/config/config.json
     mv server/config.override.copy.mk server/config.override.mk
     ```

     - These files contain the necessary settings for enabling Elasticsearch and running the required Docker services (including Elasticsearch, Postgres, etc.) on an M1 Mac or similar environment.

- **To run the server:**
  1. In the `server` directory, run:

     ```zsh
     make run-server
     ```

     This command automatically starts the necessary Docker containers (including Elasticsearch if configured in `config.override.mk`) and then runs the server.

- **To configure Elasticsearch in the webapp:**
  1. Go to System Console → Environment → ElasticSearch.

## Next Steps

- Enable Elasticsearch, reindex, and compare search performance.
