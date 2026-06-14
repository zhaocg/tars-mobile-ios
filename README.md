# Tars Mobile iOS

Native iOS client for talking to a self-hosted Tars WebChat server.

## Current step

This first step creates the app shell and the API boundary:

- SwiftUI application scaffold.
- Server URL and session ID settings.
- Tars HTTP client for health, sessions, transcript, and message submission.
- SSE client for `/sessions/{sessionId}/events`.
- Chat screen with streaming `message.delta` support.
- `WKWebView` message renderer with bundled `markdown-it` and `echarts`.

## Open in Xcode

Open `TarsMobile.xcodeproj` on macOS with Xcode 15 or newer.

The default server URL is:

```text
http://127.0.0.1:18991
```

For a physical iPhone, replace `127.0.0.1` with the LAN IP address of the machine running Tars.

## Tars endpoints used

- `GET /health`
- `GET /sessions`
- `GET /sessions/{sessionId}/transcript`
- `GET /sessions/{sessionId}/events`
- `POST /sessions/{sessionId}/messages`

Messages are submitted with:

```json
{
  "message": "Hello",
  "stream": true,
  "background": true
}
```

The app keeps an SSE subscription open and renders `message.delta`, `transcript.updated`,
`message.completed`, `message.error`, and `tool.started` events.

## Next steps

## Markdown and charts

Assistant, tool, system, and user message content is rendered through `markdown-it` inside
`WKWebView`. Raw HTML and images are disabled; links are limited to `http:`, `https:`, and
`mailto:` and open outside the message renderer.

Charts use the same controlled chart block format as WebChat:

````markdown
```chart
{
  "type": "line",
  "title": "Requests",
  "labels": ["Mon", "Tue", "Wed"],
  "series": [
    { "name": "API", "data": [12, 18, 9] }
  ]
}
```
````

Supported chart types are:

- `line`
- `bar`
- `pie`

The mobile client also accepts `echarts` as a fenced block language alias, but the JSON schema
is still the controlled Tars chart spec. It does not accept arbitrary ECharts options or JavaScript.

## Next steps

1. Add pairing/auth so the mobile app is not an unauthenticated LAN client.
2. Add tool approval cards and notification support.
3. Add a native session list and session creation flow.
