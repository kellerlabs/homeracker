// Values mirror models/core/lib/constants.scad. Keep them in sync.
export const BASE_UNIT = 15;
export const BASE_STRENGTH = 2;
export const TOLERANCE = 0.2;

export const HR_YELLOW = "#f7b600";
export const HR_BLUE = "#0056b3";
export const HR_RED = "#c41e3a";
export const HR_GREEN = "#2d7a2e";
export const HR_CHARCOAL = "#333333";
export const HR_WHITE = "#f0f0f0";

export const LIMITS = {
  /** The support part itself (a foot insert uses a 1-unit one). */
  support: { min: 1, max: 50 },
  /**
   * A support between two connectors: each arm wraps one unit of it, so two connectors need at least
   * two units between them. Applies to depth, row heights, column widths and any beam on a frame.
   */
  span: { min: 2, max: 50 },
  /** panel.scad only requires 2 units per side; the upper bound is the support length. */
  panel: { min: 2, max: 50 },
  /** The Customizer sliders in panel.scad stop at 16; larger panels need the value typed in or a split print. */
  panelCustomizer: 16,
} as const;
