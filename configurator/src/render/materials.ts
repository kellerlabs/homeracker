import { MeshStandardMaterial } from "three";
import { HR_BLUE, HR_CHARCOAL, HR_RED, HR_WHITE, HR_YELLOW } from "../engine/constants";

/** Panels read as printed plates: a matte bone white keeps them distinct from the yellow supports and white pull-through cores. */
const PANEL_COLOR = "#d9d6cc";
import type { BoxKind } from "./layout";

/** Parts that do not fit the print bed are drawn in the warning red. */
export const FLAGGED_COLOR = "#ff4d6a";

export function createMaterials(): Record<BoxKind | "flagged", MeshStandardMaterial> {
  return {
    flagged: new MeshStandardMaterial({ color: FLAGGED_COLOR, emissive: FLAGGED_COLOR, emissiveIntensity: 0.25, roughness: 0.6 }),
    support: new MeshStandardMaterial({ color: HR_YELLOW }),
    core: new MeshStandardMaterial({ color: HR_BLUE }),
    "core-pullthrough": new MeshStandardMaterial({ color: HR_WHITE }),
    arm: new MeshStandardMaterial({ color: HR_CHARCOAL }),
    foot: new MeshStandardMaterial({ color: HR_RED }),
    panel: new MeshStandardMaterial({ color: PANEL_COLOR, roughness: 0.75, metalness: 0.02 }),
  };
}
