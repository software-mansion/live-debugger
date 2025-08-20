async function getLiveDebuggerSessionURL(browserElement) {
  return new Promise((resolve, reject) => {
    const script = `
      (function() {
        try {
          const metaTag = document.querySelector('meta[name="live-debugger-config"]');
          if (!metaTag) {
            throw new Error("LiveDebugger meta tag not found!");
          }

          let sessionId = null;
          let el;
          if ((el = document.querySelector('[data-phx-main]'))) {
            sessionId = el.id;
          } else if ((el = document.querySelector('[id^="phx-"]'))) {
            sessionId = el.id;
          } else if ((el = document.querySelector('[data-phx-root-id]'))) {
            sessionId = el.getAttribute('data-phx-root-id');
          }

          return {
            url: metaTag.getAttribute('url'),
            version: metaTag.getAttribute('version'),
            sessionId: sessionId
          };
        } catch (error) {
          throw error;
        }
      })();
    `;

    browserElement.devtools.inspectedWindow.eval(
      script,
      (result, isException) => {
        if (isException || !result) {
          reject(new Error("Error fetching LiveDebugger session URL"));
          return;
        }

        try {
          const version = _getVersion(result);
          const url = _getSessionURL(result.url, version, result.sessionId);
          resolve(url);
        } catch (error) {
          reject(error);
        }
      }
    );
  });
}

async function allowRedirects(browserElement) {
  return new Promise((resolve, reject) => {
    const script = `
      (function() {
        const metaTag = document.querySelector('meta[name="live-debugger-config"]');
        if (metaTag) {
          return {
            version: metaTag.getAttribute('version')
          };
        }
        return null;
      })();
    `;

    browserElement.devtools.inspectedWindow.eval(
      script,
      (result, isException) => {
        if (isException) {
          reject(new Error("Error checking allow redirects"));
          return;
        }

        if (result) {
          const version = _getVersion(result);
          const shouldAllow = _isVersionLessThan(version, "0.4");
          resolve(shouldAllow);
          return;
        }

        resolve(false);
      }
    );
  });
}

function _getVersion(metaTagData) {
  return metaTagData.version ? metaTagData.version : "0.2";
}

function _getSessionURL(baseURL, version, sessionId) {
  let prefix = "";
  if (version.startsWith("0.2")) {
    prefix = "transport_pid";
  } else {
    prefix = "redirect";
  }
  const session_path = sessionId ? `${prefix}/${sessionId}` : "";
  return `${baseURL}/${session_path}`;
}

function _isVersionLessThan(version, targetVersion) {
  const versionNumber = parseFloat(version);
  const targetNumber = parseFloat(targetVersion);
  return versionNumber < targetNumber;
}
