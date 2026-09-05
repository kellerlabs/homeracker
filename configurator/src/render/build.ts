import { BoxGeometry, Group, Mesh, type MeshStandardMaterial } from "three";
import type { RackModel } from "../engine/types";
import { rackBoxes, type BoxKind } from "./layout";

const unitBox = new BoxGeometry(1, 1, 1);

export function buildRackGroup(
  model: RackModel,
  materials: Record<BoxKind | "flagged", MeshStandardMaterial>,
  flagged: Set<string> = new Set(),
): Group {
  const group = new Group();
  for (const box of rackBoxes(model)) {
    const problem = box.key === "panel:blocked" || (box.key !== undefined && flagged.has(box.key));
    const mesh = new Mesh(unitBox, problem ? materials.flagged : materials[box.kind]);
    mesh.position.set(box.center[0], box.center[1], box.center[2]);
    mesh.scale.set(box.size[0], box.size[1], box.size[2]);
    group.add(mesh);
  }
  return group;
}
