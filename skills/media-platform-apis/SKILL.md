---
name: media-platform-apis
description: "API integrations for media platforms: GIF search (Tenor), music streaming (Spotify), YouTube transcripts, and other media content retrieval services."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [media, gif, spotify, youtube, music, video, content, api]
    category: media
---

# Media Platform APIs

Unified reference for media platform API integrations. Each service is a labeled subsection below. All follow the same pattern: API key auth + curl-based queries + structured JSON output.

This umbrella consolidates the former `gif-search`, `spotify`, and `youtube-content` skills — merged because they all wrap media content retrieval APIs with the same auth and query workflow.

---

## GIF Search (Tenor API)

Search and download GIFs via the Tenor API using curl. No extra tools needed.

### Setup

Set `TENOR_API_KEY` in `~/.hermes/.env`. Get a free key at https://developers.google.com/tenor/guides/quickstart.

### Search

```bash
curl -s "https://tenor.googleapis.com/v2/search?q=thumbs+up&limit=5&key=${TENOR_API_KEY}" | jq -r '.results[].media_formats.gif.url'
```

Formats: `gif` (full), `tinygif` (preview), `mp4`, `tinymp4`, `webm`, `nanogif`.

### Parameters

| Parameter | Description |
|-----------|-------------|
| `q` | Search query (URL-encode spaces as `+`) |
| `limit` | Max results (1-50, default 20) |
| `contentfilter` | Safety: `off`, `low`, `medium`, `high` |

### Download

```bash
URL=$(curl -s "https://tenor.googleapis.com/v2/search?q=celebration&limit=1&key=${TENOR_API_KEY}" | jq -r '.results[0].media_formats.gif.url')
curl -sL "$URL" -o celebration.gif
```

---

## Spotify (Web API via curl)

Control playback, search, and manage playlists via the Spotify Web API.

### Setup

Get a Spotify API key from https://developer.spotify.com/console/. Set `SPOTIFY_API_KEY` in your environment.

### Search

```bash
curl -s -X GET "https://api.spotify.com/v1/search?q=artist:Radiohead&type=track&limit=5" \
  -H "Authorization: Bearer $SPOTIFY_API_KEY" | jq '.tracks.items[] | {name, artist: .artists[0].name, album: .album.name}'
```

### Get Currently Playing

```bash
curl -s -X GET "https://api.spotify.com/v1/me/player/currently-playing" \
  -H "Authorization: Bearer $SPOTIFY_API_KEY" | jq '{item: .item.name, artist: .item.artists[0].name}'
```

### Start/Resume Playback

```bash
curl -s -X PUT "https://api.spotify.com/v1/me/player/play" \
  -H "Authorization: Bearer $SPOTIFY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"context_uri": "spotify:album:5UoWLi98eUKi1gDkM5o0Vq"}'
```

### Pause

```bash
curl -s -X PUT "https://api.spotify.com/v1/me/player/pause" \
  -H "Authorization: Bearer $SPOTIFY_API_KEY"
```

### Get Playlists

```bash
curl -s -X GET "https://api.spotify.com/v1/me/playlists?limit=10" \
  -H "Authorization: Bearer $SPOTIFY_API_KEY" | jq '.items[] | {name, tracks: .tracks.total}'
```

### Notes

- Requires an active Spotify device (phone, computer, or speaker) for playback commands
- The API key must have the `user-modify-playback-state` scope for play/pause/skip
- Rate limit: 180 requests per minute

---

## YouTube Content (Transcripts & Summaries)

Extract YouTube video transcripts, generate summaries, threads, and blog posts from video content.

### Transcript Extraction

Use `youtube_transcript_api`:

```bash
pip install youtube-transcript-api
```

```python
from youtube_transcript_api import YouTubeTranscriptApi

transcript = YouTubeTranscriptApi.get_transcript("VIDEO_ID")
for entry in transcript:
    print(f"[{entry['start']:.1f}s] {entry['text']}")
```

### Formats

```python
# Plain text
text = " ".join([entry["text"] for entry in transcript])

# Timestamped (SRT-like)
for entry in transcript:
    print(f"{entry['start']:.1f} - {entry['start'] + entry['duration']:.1f}: {entry['text']}")
```

### Video ID Extraction

Extract the video ID from various YouTube URL formats:

```python
import re

def extract_video_id(url):
    patterns = [
        r"(?:youtube\.com/watch\?v=)([\w-]+)",
        r"(?:youtu\.be/)([\w-]+)",
        r"(?:youtube\.com/embed/)([\w-]+)",
        r"(?:youtube\.com/shorts/)([\w-]+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None
```

### Auto-Generated vs Manual Transcripts

```python
# Try manual first, fall back to auto-generated
try:
    transcript = YouTubeTranscriptApi.get_transcript("VIDEO_ID")
except:
    transcript = YouTubeTranscriptApi.get_transcript("VIDEO_ID", languages=['en'])

# List available languages
transcript_list = YouTubeTranscriptApi.list_transcripts("VIDEO_ID")
for t in transcript_list:
    print(f"{t.language} ({t.language_code}) - {'generated' if t.is_generated else 'manual'}")
```

### Content Generation Workflows

- **Summary**: Extract key points (3-5 bullet points) from the transcript
- **Thread**: Convert timestamps + content into a multi-post X/Twitter thread
- **Blog post**: Expand transcript into a structured article with sections
- **Key quotes**: Extract the most quotable 1-2 sentences with timestamps