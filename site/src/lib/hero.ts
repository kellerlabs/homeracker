import {
  AmbientLight,
  BufferGeometry,
  DirectionalLight,
  Group,
  Matrix4,
  Mesh,
  MeshStandardMaterial,
  PerspectiveCamera,
  Quaternion,
  Scene,
  Vector3,
  WebGLRenderer,
} from "three";
import { STLLoader } from "three/addons/loaders/STLLoader.js";
import { mountHeroRack } from "./rack";

const UNIT = 15;
/** Node spacing of the demo cube: 3-unit supports between 1-unit connector cores. */
const SPAN = 4 * UNIT;
const CENTER = new Vector3(SPAN / 2, SPAN / 2, SPAN / 2);

type Kind = "connector" | "support" | "lockpin";
const FILES: Record<Kind, string> = { connector: "connector-3d3w", support: "support-3", lockpin: "lockpin" };

interface Manifest {
  parts: Record<string, { file: string }>;
}

interface Part {
  mesh: Mesh;
  rest: Vector3;
  explode: Vector3;
  /** Window [start, end] within the global 0..1 explosion timeline. */
  window: [number, number];
}

const COLORS = { support: "#f7b600", connector: "#0056b3", lockpin: "#333333" } as const;

function material(color: string): MeshStandardMaterial {
  return new MeshStandardMaterial({ color, roughness: 0.6, metalness: 0.05, flatShading: true });
}

/** Rotation that maps the canonical +x, +y, +z arms of a 3D3W connector onto the given signs. */
function cornerRotation(sx: number, sy: number, sz: number): Quaternion {
  const m = new Matrix4();
  if (sx * sy * sz > 0) m.makeBasis(new Vector3(sx, 0, 0), new Vector3(0, sy, 0), new Vector3(0, 0, sz));
  else m.makeBasis(new Vector3(0, sy, 0), new Vector3(sx, 0, 0), new Vector3(0, 0, sz));
  return new Quaternion().setFromRotationMatrix(m);
}

/** Rotation that maps the mesh's +y axis onto `dir`. */
function alongAxis(dir: Vector3): Quaternion {
  return new Quaternion().setFromUnitVectors(new Vector3(0, 1, 0), dir.clone().normalize());
}

function buildCube(geometries: Record<Kind, BufferGeometry>): Part[] {
  const parts: Part[] = [];
  const materials = {
    connector: material(COLORS.connector),
    support: material(COLORS.support),
    lockpin: material(COLORS.lockpin),
  };
  const WINDOW: Record<Kind, [number, number]> = { lockpin: [0, 0.35], connector: [0.5, 1], support: [0.5, 1] };
  const add = (kind: Kind, rest: Vector3, rotation: Quaternion, explode: Vector3) => {
    const mesh = new Mesh(geometries[kind], materials[kind]);
    mesh.quaternion.copy(rotation);
    parts.push({ mesh, rest, explode, window: WINDOW[kind] });
  };
  const outward = (p: Vector3) => p.clone().sub(CENTER).normalize();

  for (const cx of [0, SPAN]) {
    for (const cy of [0, SPAN]) {
      for (const cz of [0, SPAN]) {
        const corner = new Vector3(cx, cy, cz);
        const signs = [cx ? -1 : 1, cy ? -1 : 1, cz ? -1 : 1] as const;
        add("connector", corner, cornerRotation(...signs), outward(corner).multiplyScalar(1.5 * UNIT));

        const arms = [new Vector3(signs[0], 0, 0), new Vector3(0, signs[1], 0), new Vector3(0, 0, signs[2])];
        for (const arm of arms) {
          const armCenter = corner.clone().addScaledVector(arm, UNIT);
          // Pins go through the arm across its axis: vertical for horizontal arms, sideways for posts.
          const pinAxis = arm.z !== 0 ? new Vector3(1, 0, 0) : new Vector3(0, 0, 1);
          const sideOut = Math.sign(armCenter.clone().sub(CENTER).dot(pinAxis)) || 1;
          const insert = pinAxis.clone().multiplyScalar(sideOut);
          add("lockpin", armCenter, alongAxis(insert), insert.clone().multiplyScalar(1.9 * UNIT));
        }
      }
    }
  }

  const axes = [new Vector3(1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1)];
  for (const axis of axes) {
    const others = axes.filter((a) => a !== axis);
    for (const u of [0, SPAN]) {
      for (const v of [0, SPAN]) {
        const rest = axis
          .clone()
          .multiplyScalar(SPAN / 2)
          .addScaledVector(others[0]!, u)
          .addScaledVector(others[1]!, v);
        add("support", rest, alongAxis(axis), outward(rest).multiplyScalar(1.1 * UNIT));
      }
    }
  }
  return parts;
}

const easeInOut = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

/** Explosion amount 0..1 over a looping timeline: assemble, hold, explode, hold. */
function explosionAt(seconds: number): number {
  const phases: [number, (p: number) => number][] = [
    [2.2, (p) => 1 - easeInOut(p)],
    [2.6, () => 0],
    [2.2, (p) => easeInOut(p)],
    [1.6, () => 1],
  ];
  const total = phases.reduce((n, [d]) => n + d, 0);
  let t = seconds % total;
  for (const [duration, fn] of phases) {
    if (t < duration) return fn(t / duration);
    t -= duration;
  }
  return 1;
}

async function loadParts(manifest: Manifest): Promise<Record<Kind, BufferGeometry>> {
  const loader = new STLLoader();
  const entries = await Promise.all(
    (Object.keys(FILES) as Kind[]).map(async (kind) => {
      const entry = manifest.parts[FILES[kind]];
      if (!entry) throw new Error(`part ${FILES[kind]} missing from manifest`);
      const geometry = await loader.loadAsync(`${import.meta.env.BASE_URL}parts/${entry.file}`);
      geometry.computeVertexNormals();
      return [kind, geometry] as const;
    }),
  );
  return Object.fromEntries(entries) as Record<Kind, BufferGeometry>;
}

function mountExplodedCube(canvas: HTMLCanvasElement, parts: Part[]): void {
  const renderer = new WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  const scene = new Scene();
  const camera = new PerspectiveCamera(30, 1, 1, 2000);
  camera.up.set(0, 0, 1);

  scene.add(new AmbientLight("#ffffff", 0.9));
  const key = new DirectionalLight("#ffffff", 2.4);
  key.position.set(200, -260, 380);
  scene.add(key);
  const rim = new DirectionalLight("#4d95ff", 0.9);
  rim.position.set(-300, 200, 120);
  scene.add(rim);

  const pivot = new Group();
  for (const part of parts) pivot.add(part.mesh);
  scene.add(pivot);

  const radius = SPAN * 3.9;
  const resize = () => {
    const { clientWidth, clientHeight } = canvas;
    if (clientWidth === 0 || clientHeight === 0) return;
    renderer.setSize(clientWidth, clientHeight, false);
    camera.aspect = clientWidth / clientHeight;
    camera.updateProjectionMatrix();
  };

  const place = (explosion: number) => {
    for (const part of parts) {
      const [a, b] = part.window;
      const local = Math.min(Math.max((explosion - a) / (b - a), 0), 1);
      part.mesh.position.copy(part.rest).sub(CENTER).addScaledVector(part.explode, local);
    }
  };

  let angle = 0.75;
  const frame = (explosion: number) => {
    place(explosion);
    camera.position.set(Math.cos(angle) * radius, Math.sin(angle) * radius, radius * 0.62);
    camera.lookAt(0, 0, 0);
    renderer.render(scene, camera);
  };

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  new ResizeObserver(() => {
    resize();
    frame(reduceMotion ? 1 : 0);
  }).observe(canvas);
  resize();
  if (reduceMotion) {
    frame(1);
    return;
  }

  const start = performance.now();
  let last = start;
  const tick = (now: number) => {
    angle += ((now - last) / 1000) * 0.14;
    last = now;
    frame(explosionAt((now - start) / 1000));
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}

/** Exploded 3D3W cube from the real part meshes; falls back to the schematic rack when they are missing. */
export async function mountHero(canvas: HTMLCanvasElement): Promise<void> {
  try {
    const response = await fetch(`${import.meta.env.BASE_URL}parts/manifest.json`, { cache: "no-cache" });
    if (!response.ok) throw new Error(`no parts manifest (${response.status})`);
    const manifest = (await response.json()) as Manifest;
    const geometries = await loadParts(manifest);
    mountExplodedCube(canvas, buildCube(geometries));
  } catch (error) {
    console.info("hero: using schematic rack", error);
    mountHeroRack(canvas);
  }
}
