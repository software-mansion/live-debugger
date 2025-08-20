async function getLiveDebuggerSessionURL(browserElement) {
  const script = `
      (function() {
        const metaTag = document.querySelector('meta[name="live-debugger-config"]');
        if (!metaTag) {
          throw new Error("LiveDebugger meta tag not found!");
        }

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

        return {
          url: metaTag.getAttribute('url'),
          version: metaTag.getAttribute('version'),
          sessionId: getSessionId()
        };
      })();
    `;

  try {
    const { url, version, sessionId } = await _runClientScript(
      browserElement,
      script
    );

    return _getSessionURL(url, _getVersion(version), sessionId);
  } catch (error) {
    return null;
  }
}

async function allowRedirects(browserElement) {
  const script = `
      (function() {
        const metaTag = document.querySelector('meta[name="live-debugger-config"]');
        if (metaTag) {
          return metaTag.getAttribute('version');
        }
        return null;
      })();
    `;

  try {
    const version = await _runClientScript(browserElement, script);
    return _isVersionLessThan(_getVersion(version), "0.4");
  } catch (error) {
    return false;
  }
}

async function _runClientScript(browserElement, script) {
  return new Promise((resolve, reject) => {
    browserElement.devtools.inspectedWindow.eval(
      script,
      (result, isException) => {
        if (isException) {
          reject(new Error("Error running client script"));
          return;
        }
        resolve(result);
      }
    );
  });
}

function _getVersion(version) {
  return version ? version : "0.2";
}

function _getSessionURL(baseURL, version, sessionId) {
  const prefix = version.startsWith("0.2") ? "transport_pid" : "redirect";
  const session_path = sessionId ? `${prefix}/${sessionId}` : "";
  return `${baseURL}/${session_path}`;
}

function _isVersionLessThan(version, targetVersion) {
  const versionNumber = parseFloat(version);
  const targetNumber = parseFloat(targetVersion);
  return versionNumber < targetNumber;
}
