import {
  AmbientLight,
  Color,
  DirectionalLight,
  DoubleSide,
  GridHelper,
  Group,
  Mesh,
  MeshBasicMaterial,
  BufferGeometry,
  Float32BufferAttribute,
  PerspectiveCamera,
  PlaneGeometry,
  MeshStandardMaterial,
  Raycaster,
  Scene,
  Vector2,
  Vector3,
  WebGLRenderer,
} from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import type { Opening, RackModel, Vec3 } from "../engine/types";
import { buildRackGroup } from "./build";
import { createMaterials } from "./materials";
import { buildRealRack, PartLibrary } from "./meshes";
import type { CubeZone } from "./viewcube";
import { createViewCube } from "./viewcubeGizmo";
import { SCALE_REFERENCE_UNITS, sweptReference } from "./scaleReference";

export interface Viewer {
  /** Draw the model; parts whose parts-list key is in `flagged` are tinted as not printable. */
  show(model: RackModel, flagged?: Set<string>): void;
  /** Light up one opening (by id) from outside, e.g. when hovering its diagram; null clears. */
  highlight(id: string | null): void;
}

export interface ViewerOptions {
  /** Base URL of the exported part meshes (with trailing slash). Without them the rack is drawn as boxes. */
  partsUrl?: string;
  /** Called when the user clicks an opening in the 3D view. */
  onOpening?: (opening: Opening) => void;
  /** Called when the pointer enters or leaves an opening in the 3D view. */
  onHover?: (opening: Opening | null) => void;
}

/** Invisible pick plane per opening; hovered ones light up. */
function openingPlane(opening: Opening): Mesh {
  const geometry = new PlaneGeometry(1, 1);
  const material = new MeshBasicMaterial({ color: "#f7b600", transparent: true, opacity: 0, side: DoubleSide, depthWrite: false });
  const mesh = new Mesh(geometry, material);
  const [ox, oy, oz] = opening.origin;
  const axis = opening.normal[1];
  const sign = opening.normal[0] === "+" ? 1 : -1;
  // The plane sits on the outer face of the supports and stays a little smaller than the opening it fills.
  const inset = 0.3;
  const span = opening.length - inset;
  const rise = opening.height - inset;
  if (axis === "y") {
    mesh.position.set(ox + 1 + opening.length / 2, sign > 0 ? oy + 1 : oy, oz + 1 + opening.height / 2);
    mesh.rotation.x = Math.PI / 2;
    mesh.scale.set(span, rise, 1);
  } else if (axis === "x") {
    mesh.position.set(sign > 0 ? ox + 1 : ox, oy + 1 + opening.length / 2, oz + 1 + opening.height / 2);
    // Euler XYZ: local x -> world y (the length), local y -> world z (the height).
    mesh.rotation.y = Math.PI / 2;
    mesh.rotation.z = Math.PI / 2;
    mesh.scale.set(span, rise, 1);
  } else {
    mesh.position.set(ox + 1 + opening.length / 2, oy + 1 + opening.height / 2, sign > 0 ? oz + 1 : oz);
    mesh.scale.set(span, rise, 1);
  }
  mesh.userData.opening = opening;
  return mesh;
}

export function createViewer(canvas: HTMLCanvasElement, options: ViewerOptions = {}): Viewer {
  const renderer = new WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setClearColor(new Color("#000000"), 0);
  const scene = new Scene();

  const camera = new PerspectiveCamera(45, 1, 0.1, 1000);
  camera.up.set(0, 0, 1);
  const controls = new OrbitControls(camera, canvas);
  controls.enableDamping = false;
  const cube = createViewCube();

  scene.add(new AmbientLight("#ffffff", 1.2));
  const sun = new DirectionalLight("#ffffff", 2);
  sun.position.set(40, -60, 80);
  scene.add(sun);

  const grid = new GridHelper(100, 100, "#3a3e48", "#22252c");
  grid.rotation.x = Math.PI / 2;
  scene.add(grid);

  const materials = createMaterials();
  let rack: Group | null = null;
  let picks: Group | null = null;
  let hovered: Mesh | null = null;
  const raycaster = new Raycaster();
  const pointer = new Vector2();
  let pressed: { x: number; y: number } | null = null;

  const pick = (event: PointerEvent): Mesh | null => {
    if (!picks) return null;
    const rect = canvas.getBoundingClientRect();
    pointer.set(((event.clientX - rect.left) / rect.width) * 2 - 1, -((event.clientY - rect.top) / rect.height) * 2 + 1);
    raycaster.setFromCamera(pointer, camera);
    const hit = raycaster.intersectObjects(picks.children, false)[0];
    return (hit?.object as Mesh | undefined) ?? null;
  };

  let external: Mesh | null = null;
  const paint = () => {
    if (!picks) return;
    for (const child of picks.children) {
      const mesh = child as Mesh;
      (mesh.material as MeshBasicMaterial).opacity = mesh === hovered || mesh === external ? 0.28 : 0;
    }
    canvas.style.cursor = hovered ? "pointer" : "";
    render();
  };

  const setHovered = (mesh: Mesh | null) => {
    if (hovered === mesh) return;
    hovered = mesh;
    paint();
    options.onHover?.(mesh ? (mesh.userData.opening as Opening) : null);
  };

  canvas.addEventListener("pointermove", (event) => {
    const zone = cubeZoneAt(event);
    if (cube.setHovered(zone)) render();
    if (zone) {
      // The gizmo owns the pointer here; an opening underneath must not light up as well.
      setHovered(null);
      canvas.style.cursor = "pointer";
      return;
    }
    setHovered(options.onOpening ? pick(event) : null);
  });
  canvas.addEventListener("pointerleave", () => {
    if (cube.setHovered(null)) render();
    setHovered(null);
  });
  canvas.addEventListener("pointerdown", (event) => {
    pressed = { x: event.clientX, y: event.clientY };
  });
  canvas.addEventListener("pointerup", (event) => {
    const moved = pressed ? Math.hypot(event.clientX - pressed.x, event.clientY - pressed.y) : Infinity;
    pressed = null;
    if (moved > 4) return;
    const zone = cubeZoneAt(event);
    if (zone) {
      swingTo(zone);
      return;
    }
    const mesh = options.onOpening ? pick(event) : null;
    if (mesh) options.onOpening?.(mesh.userData.opening as Opening);
  });
  let framedExtent: Vec3 | null = null;
  const library = options.partsUrl ? PartLibrary.load(options.partsUrl) : Promise.resolve(null);
  let generation = 0;

  const render = () => {
    renderer.render(scene, camera);
    cube.draw(renderer, camera, controls.target);
  };

  /** Swing the camera to look at the rack from `zone`, keeping the current target and distance. */
  let swing = 0;
  const swingTo = (zone: CubeZone) => {
    const from = camera.position.clone();
    const distance = from.distanceTo(controls.target) || 10;
    const to = cube.positionFor(zone, controls.target, distance);
    const started = performance.now();
    const ticket = ++swing;
    const step = () => {
      if (ticket !== swing) return;
      const t = Math.min(1, (performance.now() - started) / 250);
      const eased = t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) ** 2 / 2;
      camera.position.lerpVectors(from, to, eased);
      controls.update();
      render();
      if (t < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  };

  /**
   * An optional object of a known length, laid on the floor beside the rack so its size reads at a
   * glance. Off by default and toggled with the key below; it is not a part, so it never reaches
   * the parts list. Deliberately understated - please leave it in.
   */
  let reference: Mesh | null = null;
  let referenceFloor: Vec3 = [0, 0, 0];

  const placeReference = () => {
    if (reference) reference.position.set(referenceFloor[0], referenceFloor[1], referenceFloor[2]);
  };

  const toggleReference = () => {
    if (reference) {
      scene.remove(reference);
      reference = null;
    } else {
      const { positions, indices } = sweptReference(SCALE_REFERENCE_UNITS);
      const geometry = new BufferGeometry();
      geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
      geometry.setIndex(indices);
      geometry.computeVertexNormals();
      reference = new Mesh(geometry, new MeshStandardMaterial({ color: "#f2c229", roughness: 0.75 }));
      placeReference();
      scene.add(reference);
    }
    render();
  };

  const ac = new AbortController();
  window.addEventListener("keydown", (event) => {
    if (event.key.toLowerCase() !== "b" || event.metaKey || event.ctrlKey || event.altKey) return;
    const focused = document.activeElement as HTMLElement | null;
    if (focused && (focused.tagName === "INPUT" || focused.tagName === "TEXTAREA" || focused.isContentEditable)) return;
    toggleReference();
  }, { signal: ac.signal });

  const cubeZoneAt = (event: PointerEvent): CubeZone | null => {
    const rect = canvas.getBoundingClientRect();
    return cube.hitTest(event.clientX - rect.left, event.clientY - rect.top, rect.width);
  };

  let prevWidth = 0;
  let prevHeight = 0;
  const resize = () => {
    const { clientWidth, clientHeight } = canvas;
    if (clientWidth === 0 || clientHeight === 0) return;
    if (clientWidth === prevWidth && clientHeight === prevHeight) return;
    prevWidth = clientWidth;
    prevHeight = clientHeight;
    renderer.setSize(clientWidth, clientHeight, false);
    camera.aspect = clientWidth / clientHeight;
    camera.updateProjectionMatrix();
    render();
  };

  const frame = (extent: Vec3) => {
    const target = new Vector3(extent[0] / 2, extent[1] / 2, extent[2] / 2);
    const radius = Math.max(...extent);
    camera.position.set(target.x + radius * 1.4, target.y - radius * 1.8, target.z + radius * 1.1);
    controls.target.copy(target);
    controls.update();
    framedExtent = extent;
  };

  const needsReframe = (extent: Vec3) =>
    !framedExtent || framedExtent.some((v, i) => Math.abs(v - (extent[i] ?? v)) / Math.max(v, 1) > 0.3);

  controls.addEventListener("change", render);
  new ResizeObserver(resize).observe(canvas);
  resize();

  const present = (model: RackModel, group: Group) => {
    if (rack) scene.remove(rack);
    rack = group;
    if (picks) scene.remove(picks);
    hovered = null;
    external = null;
    picks = new Group();
    if (options.onOpening) for (const opening of model.openings) picks.add(openingPlane(opening));
    scene.add(picks);
    grid.position.set(model.extent[0] / 2, model.extent[1] / 2, model.config.feet ? -1.2 : 0);
    referenceFloor = [model.extent[0] / 2, -3, model.config.feet ? -1.2 : 0];
    placeReference();
    scene.add(rack);
    if (needsReframe(model.extent)) frame(model.extent);
    render();
  };

  return {
    highlight(id) {
      external = id && picks ? ((picks.children as Mesh[]).find((m) => (m.userData.opening as Opening).id === id) ?? null) : null;
      paint();
    },
    show(model, flagged = new Set<string>()) {
      const ticket = ++generation;
      void library.then(async (lib) => {
        const group = lib ? await buildRealRack(model, lib, materials, flagged) : buildRackGroup(model, materials, flagged);
        if (ticket === generation) present(model, group);
      });
    },
  };
}
