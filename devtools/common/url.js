function getLiveDebuggerSessionURL(browserElement) {
  return new Promise((resolve, reject) => {
    const script = `
      (function() {
        function getSessionId() {
          let el;
          if ((el = document.querySelector('[data-phx-main]'))) {
            return el.id;
          }
          if ((el = document.querySelector('[id^="phx-"]'))) {
            return el.id;
          }
          if ((el = document.querySelector('[data-phx-root-id]'))) {
            return el.getAttribute('data-phx-root-id');
          }
          return null;
        }

        function handleMetaTagError() {
          throw new Error("LiveDebugger meta tag not found!");
        }

        function getLiveDebuggerBaseURL() {
          const metaTag = document.querySelector('meta[name="live-debugger-config"]');
          if (metaTag) {
            return metaTag.getAttribute('url');
          } else {
            handleMetaTagError();
          }
        }

        function getSessionURL(baseURL) {
          const session_id = getSessionId();
          const session_path = session_id ? \`redirect/\${session_id}\` : '';
          return \`\${baseURL}/\${session_path}\`;
        }

        const baseURL = getLiveDebuggerBaseURL();
        return getSessionURL(baseURL);
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
      },
    );
  });
}
