function getLiveDebuggerSessionURL(browserElement) {
  return new Promise((resolve, reject) => {
    const script = `
      (function() {
        function getMetaTag() {
          const metaTag = document.querySelector('meta[name="live-debugger-config"]');
          if (metaTag) {
            return metaTag;
          } else {
            handleMetaTagError();
          }
        }

        function handleMetaTagError() {
          throw new Error("LiveDebugger meta tag not found!");
        }

        function getLiveDebuggerBaseURL(metaTag) {
          return metaTag.getAttribute('url');
        }

        function getVersion(metaTag) {
          const version = metaTag.getAttribute('version');
          return version ? version : "0.2"
        }

        function getSessionId() {
          let el;
          if ((el = document.querySelector('[data-phx-main]'))) {
          return null;
        }

        function getSessionURL(baseURL, version, sessionId) {
          let prefix = '';
          if (version.startsWith("0.2")) {
            prefix = "transport_pid";
          } else {
            prefix = "redirect";
          }

          const session_path = sessionId ? \`\${prefix}/\${sessionId}\` : '';
          return \`\${baseURL}/\${session_path}\`;
        }

        const metaTag = getMetaTag();

        const version = getVersion(metaTag);
        const baseURL = getLiveDebuggerBaseURL(metaTag);
        const sessionId = getSessionId();
        const url = getSessionURL(baseURL, version, sessionId);
        
        return url;
      })();
    `;

    browserElement.devtools.inspectedWindow.eval(
      script,
      (result, isException) => {
        if (isException || !result) {
          reject(new Error("Error fetching LiveDebugger session URL"));
        } else {
          resolve(result);
        }
      }
    );
  });
}
