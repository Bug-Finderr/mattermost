# Mattermost Elasticsearch Integration Project

## Problem Statement

Mattermost's open-source SQL search struggles with large datasets (>2.5M posts), leading to slow performance and timeouts. The enterprise-grade Elasticsearch integration exists but is license-restricted.

## Solution Approach

1. **Enable Enterprise Features**: Unlocked the existing Elasticsearch implementation in the Team Edition by modifications.
2. **Benchmark Testing**: Found an approach to compare SQL vs. Elasticsearch performance.

## Implementation Details

### 1. Elasticsearch Integration

The Mattermost platform already includes a robust Elasticsearch integration in the `server/enterprise/elasticsearch` directory, which provides:

- Full text search across messages, files, and users
- Autocomplete functionality with real-time suggestions
- Language-aware tokenization and stemming
- Result highlighting and relevance ranking

My implementation focused on enabling this existing functionality in the Team Edition.

### 2. Data Generation for Testing

> **Note:** I've removed my data generation scripts from this repository. The approach below is simpler to use.

## Usage Instructions

### 1. Setup

1. Configure Elasticsearch settings:

   ```bash
   # Copy provided configuration files
   cp server/config.copy.json server/config/config.json
   cp server/config.override.example.mk server/config.override.mk
   
   # Edit the config files as needed
   code server/config/config.json
   ```

2. Start the server with Elasticsearch:

   ```bash
   cd server && make run-server
   ```

3. Generate initial data:

   Instead of using just `server/bin/mmctl sampledata --local` as mentioned in the [developer setup guide](https://developers.mattermost.com/contribute/developer-setup/), use this below command:

   ```bash
   server/bin/mmctl sampledata --posts-per-channel 5000 --channels-per-team 100 --teams 10 --local
   ```

> **Note:** This is still a work in progress and hasn't been fully tested.

4. Configure via System Console:
    - Navigate to System Console → Environment → ElasticSearch
    - Set connection details (default: <http://elasticsearch:9200>)
    - Enable indexing, then build the index
    - Enable Elasticsearch for search queries and autocomplete

### 2. Monitor Performance

You can either check the Volumes section in Docker Desktop or use the following command to check the size of the database and the number of posts:

```bash
POSTGRES_CONTAINER=$(docker ps | grep postgres | awk '{print $1}')

docker exec -it $POSTGRES_CONTAINER psql -U mmuser -d mattermost_test -c \
  "SELECT pg_size_pretty(pg_total_relation_size('Posts')) AS total_size, COUNT(*) AS row_count FROM Posts;"
```

## Data Generation Evolution

### Initial Approach and Lessons Learned

My initial data generation approach had limitations that affected testing quality:

- All posts were created by a single user
- Posts went into a single channel
- Content varied only by post number and a random suffix
- No threading or conversational structure

Perf testing with this dataset showed minimal difference between SQL and Elasticsearch search despite 5M+ posts, which contradicted Mattermost's documentation about performance differences. This was likely because:

1. Modern SQL databases can efficiently query homogeneous data, even at scale
2. Elasticsearch's advantages only become apparent with diverse, complex content
3. Real-world communication patterns (threads, multiple channels, varied authors) are required for meaningful benchmarking

## Understanding Mattermost's Elasticsearch Implementation

The Mattermost team designed their Elasticsearch integration with great architectural consideration. Looking at their implementation:

1. **Pluggable Architecture**:
   - The Elasticsearch engine is designed as a pluggable backend that can replace or augment the default database search
   - Clear separation between search interface and implementation allows seamless switching between engines

2. **Index Management**:
   - Uses optimized index structure with user, channel, and post indices
   - Post indexes are intelligently aggregated by date with configurable thresholds
   - Built-in management for index lifecycle, updates, and purging

3. **Advanced Integration Features**:
   - Near real-time indexing with automatic job creation on post/user/channel changes
   - Batch processing system for large-scale operations
   - Robust error handling and recovery for interrupted indexing

4. **Performance Optimizations**:
   - Custom analyzers tailored for chat communication patterns
   - Low overhead sync between database and search indices
   - Efficient query construction to leverage Elasticsearch strengths
   - Support for index aliasing to prevent downtime during reindexing

The existing implementation is comprehensive, handling not just document search but also autocomplete, permissions, and channel-specific contexts.

## Performance Evaluation

**Work in Progress.** Initial observations suggest:

- SQL search remains responsive for simple queries but degrades with complex terms
- Elasticsearch shows consistent performance regardless of query complexity

> **Note:** This is still a work in progress and hasn't been fully tested.

## References

- [Official Elasticsearch Documentation](https://docs.mattermost.com/scale/elasticsearch.html)

<br />

> _NOTE: This README was formatted by copilot_
