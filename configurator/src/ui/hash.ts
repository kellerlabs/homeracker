import type { RackConfig } from "../engine/types";
import { decodeConfig, encodeConfig } from "../engine/url";

export function readHash(): RackConfig | null {
  return decodeConfig(window.location.hash);
}

export function writeHash(config: RackConfig): void {
  const hash = `#${encodeConfig(config)}`;
  if (window.location.hash !== hash) history.replaceState(null, "", hash);
}

export function shareUrl(config: RackConfig): string {
  return `${window.location.origin}${window.location.pathname}#${encodeConfig(config)}`;
}

export function onHashChange(handler: (config: RackConfig) => void): void {
  window.addEventListener("hashchange", () => {
    const config = readHash();
    if (config) handler(config);
  });
}
