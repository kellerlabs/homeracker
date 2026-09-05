import type { RackConfig } from "./types";

/** 6 x 6 footprint, two rows 5 and 4 units high, feet on: the README-style starter rack. */
export function defaultConfig(): RackConfig {
  return {
    depth: 6,
    rows: [
      { height: 5, columns: [6], shift: 0, through: false },
      { height: 4, columns: [6], shift: 0, through: false },
    ],
    feet: true,
    panels: [],
  };
}
