import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { getApline, getLiveSocket } from "./setup.js";
window.Alpine = getApline();
window.liveSocket = getLiveSocket(LiveSocket, Socket);
