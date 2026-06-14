import SwiftUI
import UIKit
import WebKit

struct MarkdownChartView: View {
    let markdown: String
    @State private var height: CGFloat = 44

    var body: some View {
        MarkdownChartWebView(markdown: markdown, height: $height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
    }
}

struct MarkdownChartWebView: UIViewRepresentable {
    let markdown: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: "tarsRenderer")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastMarkdown != markdown else {
            return
        }

        context.coordinator.lastMarkdown = markdown
        webView.loadHTMLString(Self.html(for: markdown), baseURL: Bundle.main.resourceURL)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "tarsRenderer")
    }

    private static func html(for markdown: String) -> String {
        let source = javascriptString(markdown)

        return """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <script src="Vendor/markdown-it.min.js"></script>
            <script src="Vendor/echarts.min.js"></script>
            <style>
              :root {
                color-scheme: light dark;
                font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
                font-size: 16px;
                --text: #1f2933;
                --muted: #637083;
                --line: rgba(31, 41, 51, 0.14);
                --soft: rgba(15, 23, 42, 0.04);
                --link: #0b7f7a;
                --code-bg: rgba(15, 23, 42, 0.06);
              }
              body {
                margin: 0;
                padding: 0;
                background: transparent;
                color: var(--text);
                line-height: 1.45;
                overflow-wrap: anywhere;
              }
              .markdown-body > :first-child {
                margin-top: 0;
              }
              .markdown-body > :last-child {
                margin-bottom: 0;
              }
              p, ul, ol, blockquote, pre, table {
                margin: 0 0 12px;
              }
              h1, h2, h3, h4, h5, h6 {
                margin: 16px 0 8px;
                line-height: 1.22;
              }
              h1 { font-size: 24px; }
              h2 { font-size: 21px; }
              h3 { font-size: 18px; }
              h4, h5, h6 { font-size: 16px; }
              ul, ol {
                padding-left: 22px;
              }
              li + li {
                margin-top: 4px;
              }
              blockquote {
                color: var(--muted);
                border-left: 3px solid var(--line);
                padding-left: 12px;
              }
              a {
                color: var(--link);
                font-weight: 650;
                text-decoration-thickness: 1px;
                text-underline-offset: 2px;
              }
              table {
                width: 100%;
                border-collapse: collapse;
                display: block;
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
              }
              th, td {
                border: 1px solid var(--line);
                padding: 7px 9px;
                text-align: left;
                vertical-align: top;
                white-space: nowrap;
              }
              th {
                background: var(--soft);
                font-weight: 750;
              }
              pre, code {
                font-family: "SF Mono", Menlo, monospace;
                font-size: 14px;
              }
              code {
                background: var(--code-bg);
                border-radius: 5px;
                padding: 1px 4px;
              }
              pre {
                background: var(--code-bg);
                border-radius: 8px;
                overflow-x: auto;
                padding: 10px 12px;
                -webkit-overflow-scrolling: touch;
              }
              pre code {
                background: transparent;
                border-radius: 0;
                padding: 0;
              }
              .chart-block {
                width: 100%;
                min-height: 280px;
                border: 1px solid var(--line);
                border-radius: 8px;
                background: rgba(255, 255, 255, 0.86);
                margin: 0 0 12px;
              }
              .chart-error {
                border: 1px solid rgba(180, 35, 24, 0.32);
                color: #b42318;
              }
              @media (prefers-color-scheme: dark) {
                :root {
                  --text: #e7edf5;
                  --muted: #9ba7b7;
                  --line: rgba(231, 237, 245, 0.16);
                  --soft: rgba(255, 255, 255, 0.06);
                  --link: #39c6bd;
                  --code-bg: rgba(255, 255, 255, 0.08);
                }
                .chart-block {
                  background: rgba(16, 24, 32, 0.88);
                }
              }
            </style>
          </head>
          <body>
            <main id="content" class="markdown-body"></main>
            <script>
              const SOURCE = \(source);
              const content = document.getElementById('content');
              const markdownRenderer = createMarkdownRenderer();

              renderMarkdown(content, SOURCE);
              postHeight();

              if (typeof ResizeObserver === 'function') {
                const bodyObserver = new ResizeObserver(postHeight);
                bodyObserver.observe(document.documentElement);
                bodyObserver.observe(document.body);
                bodyObserver.observe(content);
              }

              window.addEventListener('load', postHeight);
              window.addEventListener('resize', postHeight);
              setTimeout(postHeight, 80);
              setTimeout(postHeight, 320);

              function createMarkdownRenderer() {
                if (typeof window.markdownit !== 'function') {
                  return undefined;
                }

                const renderer = window.markdownit({
                  html: false,
                  linkify: true,
                  typographer: false,
                  breaks: true
                });
                renderer.disable('image');
                return renderer;
              }

              function renderMarkdown(container, source) {
                container.innerHTML = '';
                const markdown = String(source ?? '');

                if (markdownRenderer === undefined) {
                  container.textContent = markdown;
                  return;
                }

                container.innerHTML = markdownRenderer.render(markdown);
                sanitizeRenderedMarkdown(container);
              }

              function sanitizeRenderedMarkdown(container) {
                container.querySelectorAll('a').forEach((link) => {
                  const safeHref = sanitizeMarkdownHref(link.getAttribute('href') ?? '');

                  if (safeHref === undefined) {
                    link.replaceWith(document.createTextNode(link.textContent ?? ''));
                    return;
                  }

                  link.href = safeHref;
                  link.target = '_blank';
                  link.rel = 'noreferrer';
                });

                container.querySelectorAll('img').forEach((image) => {
                  image.replaceWith(document.createTextNode(image.getAttribute('alt') ?? ''));
                });

                renderChartBlocks(container);
              }

              function renderChartBlocks(container) {
                container
                  .querySelectorAll('pre > code.language-chart, pre > code.language-echarts')
                  .forEach((code) => {
                    const pre = code.parentElement;
                    const spec = normalizeChartSpec(parseChartSpec(code.textContent ?? ''));

                    if (pre === null || spec === undefined || typeof window.echarts !== 'object') {
                      pre?.classList.add('chart-error');
                      return;
                    }

                    const chartBlock = document.createElement('div');
                    chartBlock.className = 'chart-block';
                    chartBlock.setAttribute('role', 'img');
                    chartBlock.setAttribute('aria-label', spec.title || spec.type + ' chart');
                    pre.replaceWith(chartBlock);
                    renderEChartsBlock(chartBlock, spec);
                  });
              }

              function parseChartSpec(source) {
                try {
                  return JSON.parse(source);
                } catch {
                  return undefined;
                }
              }

              function normalizeChartSpec(value) {
                if (value === null || typeof value !== 'object') {
                  return undefined;
                }

                const type = ['line', 'bar', 'pie'].includes(value.type) ? value.type : undefined;
                const seriesInput = Array.isArray(value.series)
                  ? value.series
                  : Array.isArray(value.data)
                    ? [{ name: value.title, data: value.data }]
                    : [];
                const series = seriesInput
                  .map((item) => normalizeChartSeries(item))
                  .filter((item) => item !== undefined);

                if (type === undefined || series.length === 0) {
                  return undefined;
                }

                const maxLength = Math.max(...series.map((item) => item.data.length));
                const labels = normalizeChartLabels(value.labels, maxLength);

                return {
                  type,
                  title: normalizeChartText(value.title),
                  labels,
                  series
                };
              }

              function normalizeChartSeries(value) {
                if (value === null || typeof value !== 'object' || !Array.isArray(value.data)) {
                  return undefined;
                }

                const data = value.data
                  .map((item) => Number(item))
                  .filter((item) => Number.isFinite(item))
                  .slice(0, 100);

                if (data.length === 0) {
                  return undefined;
                }

                return {
                  name: normalizeChartText(value.name) || 'Series',
                  data
                };
              }

              function normalizeChartLabels(value, count) {
                const labels = Array.isArray(value)
                  ? value.map((item) => normalizeChartText(item)).filter((item) => item !== '')
                  : [];

                if (labels.length >= count) {
                  return labels.slice(0, 100);
                }

                return Array.from({ length: count }, (_item, index) =>
                  labels[index] || String(index + 1)
                );
              }

              function normalizeChartText(value) {
                return typeof value === 'string'
                  ? value.trim().slice(0, 120)
                  : '';
              }

              function renderEChartsBlock(chartBlock, spec) {
                const chart = window.echarts.init(chartBlock, undefined, {
                  renderer: 'canvas'
                });
                chart.setOption(eChartsOptionFromSpec(spec), true);
                postHeight();

                if (typeof ResizeObserver === 'function') {
                  const observer = new ResizeObserver(() => {
                    chart.resize();
                    postHeight();
                  });
                  observer.observe(chartBlock);
                } else {
                  window.addEventListener('resize', () => {
                    chart.resize();
                    postHeight();
                  });
                }
              }

              function eChartsOptionFromSpec(spec) {
                const isDark = window.matchMedia
                  ? window.matchMedia('(prefers-color-scheme: dark)').matches
                  : false;
                const chartText = isDark ? '#d8e1ec' : '#243241';
                const chartMuted = isDark ? '#9ba7b7' : '#637083';
                const chartLine = isDark ? 'rgba(216, 225, 236, 0.18)' : 'rgba(36, 50, 65, 0.14)';

                const base = {
                  animation: false,
                  color: ['#14b8a6', '#2563eb', '#f59e0b', '#ef4444', '#8b5cf6'],
                  textStyle: {
                    color: chartText
                  },
                  title: spec.title === '' ? undefined : {
                    text: spec.title,
                    left: 'center',
                    textStyle: {
                      color: chartText,
                      fontSize: 14,
                      fontWeight: 700
                    }
                  },
                  tooltip: {
                    trigger: spec.type === 'pie' ? 'item' : 'axis',
                    renderMode: 'richText'
                  },
                  legend: {
                    bottom: 0,
                    textStyle: {
                      color: chartMuted
                    }
                  }
                };

                if (spec.type === 'pie') {
                  const firstSeries = spec.series[0];
                  return {
                    ...base,
                    series: [
                      {
                        name: firstSeries.name,
                        type: 'pie',
                        radius: ['35%', '65%'],
                        center: ['50%', '48%'],
                        data: firstSeries.data.map((value, index) => ({
                          name: spec.labels[index] || String(index + 1),
                          value
                        }))
                      }
                    ]
                  };
                }

                return {
                  ...base,
                  grid: {
                    left: 42,
                    right: 20,
                    top: spec.title === '' ? 20 : 54,
                    bottom: 48
                  },
                  xAxis: {
                    type: 'category',
                    data: spec.labels,
                    axisLabel: {
                      color: chartMuted
                    },
                    axisLine: {
                      lineStyle: {
                        color: chartLine
                      }
                    },
                    splitLine: {
                      lineStyle: {
                        color: chartLine
                      }
                    }
                  },
                  yAxis: {
                    type: 'value',
                    axisLabel: {
                      color: chartMuted
                    },
                    axisLine: {
                      lineStyle: {
                        color: chartLine
                      }
                    },
                    splitLine: {
                      lineStyle: {
                        color: chartLine
                      }
                    }
                  },
                  series: spec.series.map((item) => ({
                    name: item.name,
                    type: spec.type,
                    data: item.data,
                    smooth: spec.type === 'line'
                  }))
                };
              }

              function sanitizeMarkdownHref(href) {
                try {
                  const url = new URL(String(href).trim(), window.location.href);
                  if (['http:', 'https:', 'mailto:'].includes(url.protocol)) {
                    return url.href;
                  }
                } catch {
                  return undefined;
                }

                return undefined;
              }

              function postHeight() {
                const height = Math.max(
                  32,
                  Math.ceil(content.scrollHeight),
                  Math.ceil(document.body.scrollHeight),
                  Math.ceil(document.documentElement.scrollHeight)
                );

                window.webkit?.messageHandlers?.tarsRenderer?.postMessage({
                  type: 'height',
                  height
                });
              }
            </script>
          </body>
        </html>
        """
    }

    private static func javascriptString(_ value: String) -> String {
        guard
            let data = try? JSONEncoder().encode(value),
            let string = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }

        return string
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        @Binding private var height: CGFloat
        var lastMarkdown: String?

        init(height: Binding<CGFloat>) {
            self._height = height
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard
                message.name == "tarsRenderer",
                let body = message.body as? [String: Any],
                body["type"] as? String == "height",
                let nextHeight = Self.cgFloatValue(body["height"])
            else {
                return
            }

            let clampedHeight = min(max(nextHeight, 32), 12000)
            guard abs(clampedHeight - height) > 1 else {
                return
            }

            DispatchQueue.main.async {
                self.height = clampedHeight
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated else {
                return .allow
            }

            guard let url = navigationAction.request.url else {
                return .cancel
            }

            if ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }

            return .cancel
        }

        static func cgFloatValue(_ value: Any?) -> CGFloat? {
            if let number = value as? NSNumber {
                return CGFloat(number.doubleValue)
            }

            if let double = value as? Double {
                return CGFloat(double)
            }

            if let int = value as? Int {
                return CGFloat(int)
            }

            return nil
        }
    }
}
