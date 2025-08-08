## SuccessorDiscoverer

This service is responsible for finding the successor of dead LiveView in given browser window. It is used in cases when you e.g. reload webpage created by LiveView. Reload kills LiveView that hosts given page, but immediately new one is born to display this page again. We need to detect such LiveViews for smooth debugging experience.
