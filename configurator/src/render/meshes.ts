import { BoxGeometry, BufferGeometry, Group, Matrix4, Mesh, MeshStandardMaterial, Quaternion, Vector3 } from "three";
import { STLLoader } from "three/addons/loaders/STLLoader.js";
import { BASE_STRENGTH, BASE_UNIT, TOLERANCE } from "../engine/constants";
import { classifyConnector, connectorLabel } from "../engine/connector";
import { connectorLabelOf, orientConnector } from "../engine/orientation";
import type { Axis, Dir, RackModel, RackNode, RackPanel, Vec3 } from "../engine/types";
import type { BoxKind } from "./layout";

interface Manifest {
  parts: Record<string, { file: string }>;
}

/** Real part meshes exported from the OpenSCAD sources (see site/scripts/export-parts.mjs), loaded on demand. */
export class PartLibrary {
  private readonly geometries = new Map<string, Promise<BufferGeometry>>();
  private readonly loader = new STLLoader();

  private constructor(
    private readonly baseUrl: string,
    private readonly manifest: Manifest,
  ) {}

  /** Resolves to null when no manifest is served at `baseUrl`. */
  static async load(baseUrl: string): Promise<PartLibrary | null> {
    try {
      const response = await fetch(`${baseUrl}manifest.json`, { cache: "no-cache" });
      if (!response.ok) return null;
      return new PartLibrary(baseUrl, (await response.json()) as Manifest);
    } catch {
      return null;
    }
  }

  has(name: string): boolean {
    return name in this.manifest.parts;
  }

  geometry(name: string): Promise<BufferGeometry> {
    const entry = this.manifest.parts[name];
    if (!entry) throw new Error(`part ${name} is not in the library`);
    let pending = this.geometries.get(name);
    if (!pending) {
      pending = this.loader.loadAsync(`${this.baseUrl}${entry.file}`).then((g) => {
        g.computeVertexNormals();
        // Meshes are in millimetres; the scene is in HomeRacker units.
        g.scale(1 / BASE_UNIT, 1 / BASE_UNIT, 1 / BASE_UNIT);
        return g;
      });
      this.geometries.set(name, pending);
    }
    return pending;
  }
}

const AXIS_VECTOR: Record<Axis, Vector3> = { x: new Vector3(1, 0, 0), y: new Vector3(0, 1, 0), z: new Vector3(0, 0, 1) };

function dirVector(dir: Dir): Vector3 {
  return AXIS_VECTOR[dir[1] as Axis].clone().multiplyScalar(dir[0] === "+" ? 1 : -1);
}

function cellCenter(pos: Vec3): Vector3 {
  return new Vector3(pos[0] + 0.5, pos[1] + 0.5, pos[2] + 0.5);
}

/** Rotation that maps the mesh's +y axis (supports and lock pins are modelled along y) onto `dir`. */
function alongAxis(dir: Vector3): Quaternion {
  return new Quaternion().setFromUnitVectors(new Vector3(0, 1, 0), dir.clone().normalize());
}

export function connectorPartName(node: RackNode): { name: string; rotation: Quaternion } {
  const { rotation, variant } = orientConnector(node.arms, node.pullThrough);
  const label = connectorLabelOf(node.arms).toLowerCase();
  const m = new Matrix4().set(
    rotation[0]![0]!, rotation[0]![1]!, rotation[0]![2]!, 0,
    rotation[1]![0]!, rotation[1]![1]!, rotation[1]![2]!, 0,
    rotation[2]![0]!, rotation[2]![1]!, rotation[2]![2]!, 0,
    0, 0, 0, 1,
  );
  return { name: `connector-${label}${variant === "none" ? "" : `-${variant}`}`, rotation: new Quaternion().setFromRotationMatrix(m) };
}

/** Side a lock pin is pushed in from: across the arm, from the top for horizontal arms, from +x for posts. */
export function lockpinInsert(arm: Dir, armCenter: Vector3, rackCenter: Vector3): Vector3 {
  const axis = arm[1] === "z" ? AXIS_VECTOR.x : AXIS_VECTOR.z;
  const side = Math.sign(armCenter.clone().sub(rackCenter).dot(axis)) || 1;
  return axis.clone().multiplyScalar(side);
}

/** Offset of the foot mesh origin from the centre of the arm cell it plugs into (its support section is not centred). */
const FOOT_OFFSET_UNITS = -1.55 / BASE_UNIT;

export async function buildRealRack(
  model: RackModel,
  library: PartLibrary,
  materials: Record<BoxKind | "flagged", MeshStandardMaterial>,
  flagged: Set<string> = new Set(),
): Promise<Group> {
  const pick = (key: string, material: MeshStandardMaterial) => (flagged.has(key) ? materials.flagged : material);
  const group = new Group();
  const rackCenter = new Vector3(model.extent[0] / 2, model.extent[1] / 2, model.extent[2] / 2);
  const pending: Promise<void>[] = [];
  const place = (name: string, material: MeshStandardMaterial, position: Vector3, rotation: Quaternion) => {
    pending.push(
      library.geometry(name).then((geometry) => {
        const mesh = new Mesh(geometry, material);
        mesh.position.copy(position);
        mesh.quaternion.copy(rotation);
        group.add(mesh);
      }),
    );
  };

  for (const s of model.supports) {
    const center = cellCenter(s.from);
    const axis = AXIS_VECTOR[s.axis];
    center.addScaledVector(axis, (s.length - 1) / 2);
    place(`support-${s.length}`, pick(`support:${s.length}`, materials.support), center, alongAxis(axis));
  }

  for (const n of model.nodes) {
    const core = cellCenter(n.pos);
    const { name, rotation } = connectorPartName(n);
    const spec = classifyConnector(n.arms, n.pullThrough);
    const key = `connector:${connectorLabel({ ...spec, pullThrough: "none" })}:${spec.pullThrough}`;
    place(name, pick(key, n.pullThrough === "none" ? materials.core : materials["core-pullthrough"]), core, rotation);
    for (const arm of n.arms) {
      if (arm === "-z" && n.foot) {
        const cell = core.clone().add(dirVector(arm));
        place("foot", materials.foot, cell.add(new Vector3(0, 0, FOOT_OFFSET_UNITS)), new Quaternion());
        continue;
      }
      const armCenter = core.clone().add(dirVector(arm));
      const insert = lockpinInsert(arm, armCenter, rackCenter);
      place("lockpin", materials.arm, armCenter, alongAxis(insert));
    }
  }

  // Panels are parametric in two dimensions, so each one is assembled from exported mount plates and
  // corner brackets around a plate, the way panel() assembles it.
  for (const panel of model.panels) {
    // A panel no standard part fits (connector inside an edge) is drawn in the warning colour like unprintable parts.
    const material = panel.blocked ? materials.flagged : pick(`panel:${panel.unitsX}x${panel.unitsY}:${panel.type}`, materials.panel);
    pending.push(panelMesh(panel, library, material).then((g) => void group.add(g)));
  }

  await Promise.all(pending);
  return group;
}

const unitBoxGeometry = new BoxGeometry(1, 1, 1);

/** Panel geometry in units, from models/panel/lib/panel.scad. */
const MM = 1 / BASE_UNIT;
const PLATE = BASE_STRENGTH * MM;
const INTERFIT_DEDUCTION = (2 * BASE_STRENGTH + TOLERANCE) * MM;
const CORNER_MOUNT = (BASE_UNIT - BASE_STRENGTH) * MM;
/** Mount height: BASE_UNIT + TOLERANCE for inter-fit, one wall more for full cover (get_panel_mount_height). */
const MOUNT_HEIGHT = { interfit: (BASE_UNIT + TOLERANCE) * MM, fullcover: (BASE_UNIT + TOLERANCE + BASE_STRENGTH) * MM };
/** Bottom plate of a support mount plate: 2 walls + half the tolerance (support_mount_plate). */
const MOUNT_PLATE_WIDTH = (BASE_STRENGTH * 2 + TOLERANCE / 2) * MM;

/**
 * A panel assembled the way panel() in panel.scad assembles it: the plate, a real support mount
 * plate on every edge longer than 2 units, and a real corner bracket in every corner.
 * Local frame: x along the opening's length, y along its height, z pointing into the rack.
 * Mount plates and corners are exported meshes; only the plate is a box.
 */
function panelMesh(panel: RackPanel, library: PartLibrary, material: MeshStandardMaterial): Promise<Group> {
  const group = new Group();
  const n = AXES.indexOf(panel.normal[1] as Axis);
  const sign = panel.normal[0] === "+" ? 1 : -1;
  const [l, h] = [0, 1, 2].filter((i) => i !== n) as [number, number];
  const originN = panel.origin[n] ?? 0;
  const plane = sign > 0 ? originN + 1 : originN;
  const Lu = panel.unitsX;
  const Hu = panel.unitsY;
  const code = panel.type === "interfit" ? "i" : "f";
  const mountHeight = MOUNT_HEIGHT[panel.type];

  // Local -> world: x = length axis, y = height axis, z = inward (opposite the outward normal).
  const basis = [new Vector3(), new Vector3(), new Vector3()];
  basis[0]!.setComponent(l, 1);
  basis[1]!.setComponent(h, 1);
  basis[2]!.setComponent(n, -sign);
  const origin = new Vector3();
  origin.setComponent(l, (panel.origin[l] ?? 0) + 1 + Lu / 2);
  origin.setComponent(h, (panel.origin[h] ?? 0) + 1 + Hu / 2);
  origin.setComponent(n, plane);
  group.matrixAutoUpdate = false;
  group.matrix.makeBasis(basis[0]!, basis[1]!, basis[2]!).setPosition(origin);

  // Plate: inter-fit sits inside the opening flush with the outer face; full cover sits outside, one unit wider.
  const plateWidth = Lu - INTERFIT_DEDUCTION;
  const plateDepth = Hu - INTERFIT_DEDUCTION;
  const plateBottom = panel.type === "interfit" ? 0 : -PLATE;
  const plate = new Mesh(unitBoxGeometry, material);
  plate.scale.set(panel.type === "interfit" ? plateWidth : Lu + 1, panel.type === "interfit" ? plateDepth : Hu + 1, PLATE);
  plate.position.set(0, 0, plateBottom + PLATE / 2);
  group.add(plate);

  const pending: Promise<void>[] = [];
  const add = (name: string, x: number, y: number, z: number, spin: number, mirrorX = false, fallback?: [number, number, number]) => {
    if (!library.has(name)) {
      // Library without this piece (older export): keep the panel complete with a plain block of the same size.
      if (fallback) {
        const block = new Mesh(unitBoxGeometry, material);
        block.position.set(x, y, z);
        block.rotation.z = spin;
        block.scale.set(...fallback);
        group.add(block);
      }
      return;
    }
    pending.push(
      library.geometry(name).then((geometry) => {
        const mesh = new Mesh(geometry, material);
        mesh.position.set(x, y, z);
        mesh.rotation.z = spin;
        if (mirrorX) mesh.scale.x = -1;
        group.add(mesh);
      }),
    );
  };

  // Support mount plates: bottom aligned with the plate bottom, outer wall on the opening edge.
  const mountCenterZ = plateBottom + (PLATE + mountHeight) / 2;
  const inset = MOUNT_PLATE_WIDTH / 2;
  if (Hu > 2) {
    const name = `panel-mount-${code}-${Hu}`;
    const block: [number, number, number] = [MOUNT_PLATE_WIDTH, Hu - 2, PLATE + mountHeight];
    add(name, -Lu / 2 + inset, 0, mountCenterZ, 0, false, block);
    add(name, Lu / 2 - inset, 0, mountCenterZ, 0, true, block);
  }
  if (Lu > 2) {
    const name = `panel-mount-${code}-${Lu}`;
    const block: [number, number, number] = [MOUNT_PLATE_WIDTH, Lu - 2, PLATE + mountHeight];
    add(name, 0, Hu / 2 - inset, mountCenterZ, -Math.PI / 2, false, block);
    add(name, 0, -Hu / 2 + inset, mountCenterZ, Math.PI / 2, false, block);
  }

  // Corner brackets on top of the plate, spun like panel() spins them.
  const cornerZ = plateBottom + PLATE + mountHeight / 2;
  const cx = plateWidth / 2 - CORNER_MOUNT / 2;
  const cy = plateDepth / 2 - CORNER_MOUNT / 2;
  const corner = `panel-corner-${code}`;
  const cornerBlock: [number, number, number] = [CORNER_MOUNT, CORNER_MOUNT, mountHeight];
  add(corner, -cx, cy, cornerZ, 0, false, cornerBlock);
  add(corner, -cx, -cy, cornerZ, Math.PI / 2, false, cornerBlock);
  add(corner, cx, -cy, cornerZ, Math.PI, false, cornerBlock);
  add(corner, cx, cy, cornerZ, (3 * Math.PI) / 2, false, cornerBlock);

  return Promise.all(pending).then(() => group);
}

const AXES: Axis[] = ["x", "y", "z"];
