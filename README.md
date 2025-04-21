# Mattermost Elasticsearch Integration Project

## Problem Statement

Mattermost's built-in SQL search becomes slow with large amounts of data (over 2.5 million posts). The faster Elasticsearch integration is normally a paid feature.

## Solution Approach

1. **Enable Enterprise Features**: Modified the code to unlock the Elasticsearch feature in the free Team Edition.
2. **Benchmark Testing**: Improved the data generation tool (`mmctl sampledata`) to quickly create large datasets for testing search performance.

## Implementation Details

### 1. Elasticsearch Integration

Mattermost already includes code for Elasticsearch (`server/enterprise/elasticsearch`) that provides:

- Full text search (messages, files, users)
- Search suggestions (autocomplete)
- Smart searching based on language
- Highlighting search results

This project focuses on making this existing feature usable in the Team Edition.

### 2. Data Generation Optimization

The `mmctl sampledata` command (`server/cmd/mmctl/commands/sampledata.go`) was heavily optimized to create millions of posts much faster. Generating 5 million posts now takes about **1 hour**, down from **2.5 hours** with the original code.

Improvements:

1. **Parallel Processing**: Uses multiple processor cores (goroutines) to generate post data at the same time.
2. **Buffered Writing**: Writes data to the output file in large chunks (8MB buffer using `bufio.Writer`), reducing disk activity.
3. **Memory Pooling**: Reuses memory buffers (`sync.Pool` for `bytes.Buffer`) to lower memory usage and reduce pauses for cleanup (garbage collection).
4. **Efficient Date Generation**: Creates sorted dates directly for large datasets (`efficientSortedRandomDates` function) instead of generating random dates and then sorting them, saving significant time.
5. **Smart Worker Count**: Adjusts the number of parallel workers based on available CPU cores (`runtime.NumCPU()`) for better performance.

## Usage Instructions

### 1. Setup

1. Configure Elasticsearch settings:

   ```bash
   # Copy provided config files (config.copy.json has ES settings)
   cp server/config.copy.json server/config/config.json 
   cp server/config.override.mk server/config.override.mk
   
   # Optional: Edit config.json if needed
   # vim server/config/config.json
   ```

2. Start the server with Elasticsearch:

   ```bash
   cd server && make run-server
   ```

3. Generate initial data:

   Use this command instead of the basic one in the [developer setup guide](https://developers.mattermost.com/contribute/developer-setup/). It uses the optimized code:

   ```bash
   # Generates ~5 million posts (takes ~1 hour)
   server/bin/mmctl sampledata --users 100 --teams 10 --channels-per-team 10 --posts-per-channel 50000 --local
   ```

4. Add sysadmin to all teams and channels:

   Run this script to ensure the `sysadmin` user can access all generated content for testing purposes.

   ```bash
   ./i_am_admin.sh
   ```

5. Configure via System Console:
    - Log in as `sysadmin` (Password: `Sys@dmin123`).
    - Go to System Console → Environment → ElasticSearch
    - Enter connection details (usually `http://elasticsearch:9200`)
    - Click "Enable Indexing", then "Build Index"
    - Click "Enable Elasticsearch for search queries" and "Enable Elasticsearch for autocomplete"
    - **Important:** By default, both SQL and Elasticsearch search might be disabled in the configuration (`config.json`).
        - To enable **SQL Search** (for comparison): Go to `System Console → Environment → Database` and set `Disable database search` to `false`.
        - To enable **Elasticsearch Search**: Ensure `Disable database search` is set to `true` (its default) and follow the Elasticsearch enabling steps above. You need to toggle `Disable database search` depending on which system you are testing.

### 2. Monitor Performance

Run this script to check the database size and row counts for key tables:

```bash
./db_size.sh
```

## Data Generation Evolution

### Initial Approach and Lessons Learned

Early attempts at generating data created very simple, uniform posts (one user, one channel, basic content). Testing showed little difference between SQL and Elasticsearch with this simple data, even with millions of posts.

Lessons:

1. SQL databases handle simple, repetitive data well, even at scale.
2. Elasticsearch shows its strength with more varied and complex data.
3. Realistic testing needs data that mimics real usage (threads, multiple users/channels).

The optimized `mmctl sampledata` command is much faster for creating large datasets, even if the content is still somewhat uniform.

## Elasticsearch Implementation Details (License Bypass)

To enable the Elasticsearch feature, a few changes were made in `server/channels/app/platform/license.go`:

- A "fake" enterprise license object is created if a real one isn't present.
- The necessary `Elasticsearch` and `Compliance` flags were added to this fake license.
- License checks were slightly changed to accept this fake license.
- This allows the Elasticsearch engine, normally restricted, to connect to Mattermost's search interface.

**Note on Testing:** To better observe performance differences during manual testing, the post retrieval limit was increased from 100 to 1000 in `server/channels/store/sqlstore/post_store.go` (around line 2065).

## Performance Evaluation

- The optimized `mmctl sampledata` quickly creates large datasets (~1 hour for 5M+ posts).
- **Qualitative Observation:** SQL search noticeably slows down with complex search terms or filters on large datasets (5M+ posts) to return results in the UI.
- **Qualitative Observation:** Elasticsearch search speed remains consistently fast, returning results almost instantly in the UI, regardless of search complexity or dataset size.

**Measuring Precise Timings:** Accurately measuring the end-to-end search time using browser developer tools is challenging. The search action triggers multiple asynchronous network calls (initial fetch, user/channel details, etc.), making it difficult to isolate the pure search backend processing time from network latency and subsequent client-side rendering. Therefore, precise timings (like those in the previous mock table) are not provided, but the qualitative difference in user experience is significant.

## References

- [Mattermost Elasticsearch Documentation](https://docs.mattermost.com/scale/elasticsearch.html)
- [Mattermost Developer Setup Guide](https://developers.mattermost.com/contribute/developer-setup/)
- [Mattermost MMCTL Documentation](https://docs.mattermost.com/manage/mmctl-command-line-tool.html)

<br />

> _NOTE: This README was formatted by copilot_
