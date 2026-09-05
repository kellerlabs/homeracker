import {
  AmbientLight,
  BoxGeometry,
  DirectionalLight,
  Group,
  Mesh,
  MeshStandardMaterial,
  PerspectiveCamera,
  Scene,
  Vector3,
  WebGLRenderer,
} from "three";
import { defaultConfig } from "../../../configurator/src/engine/defaults";
import { buildModel } from "../../../configurator/src/engine/model";
import { rackBoxes, type BoxKind } from "../../../configurator/src/render/layout";

const COLORS: Record<BoxKind, string> = {
  support: "#f7b600",
  core: "#0056b3",
  "core-pullthrough": "#f0f0f0",
  arm: "#333333",
  foot: "#c41e3a",
  panel: "#2d7a2e",
};

/** Draw the default configurator rack on a canvas and orbit it slowly. */
export function mountHeroRack(canvas: HTMLCanvasElement): void {
  const model = buildModel(defaultConfig());
  const renderer = new WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  const scene = new Scene();
  const camera = new PerspectiveCamera(38, 1, 0.1, 200);
  camera.up.set(0, 0, 1);

  scene.add(new AmbientLight("#ffffff", 1.1));
  const key = new DirectionalLight("#ffffff", 2.2);
  key.position.set(30, -40, 60);
  scene.add(key);
  const rim = new DirectionalLight("#4d95ff", 0.8);
  rim.position.set(-40, 30, 20);
  scene.add(rim);

  const materials = new Map<BoxKind, MeshStandardMaterial>();
  const box = new BoxGeometry(1, 1, 1);
  const rack = new Group();
  for (const b of rackBoxes(model)) {
    let material = materials.get(b.kind);
    if (!material) {
      material = new MeshStandardMaterial({ color: COLORS[b.kind], roughness: 0.55, metalness: 0.1 });
      materials.set(b.kind, material);
    }
    const mesh = new Mesh(box, material);
    mesh.position.set(b.center[0], b.center[1], b.center[2]);
    mesh.scale.set(b.size[0], b.size[1], b.size[2]);
    rack.add(mesh);
  }
  const [ex, ey, ez] = model.extent;
  rack.position.set(-ex / 2, -ey / 2, -ez / 2 + 0.6);
  const pivot = new Group();
  pivot.add(rack);
  scene.add(pivot);

  const radius = Math.max(ex, ey, ez) * 1.75;
  const target = new Vector3(0, 0, 0);

  const resize = () => {
    const { clientWidth, clientHeight } = canvas;
    if (clientWidth === 0 || clientHeight === 0) return;
    renderer.setSize(clientWidth, clientHeight, false);
    camera.aspect = clientWidth / clientHeight;
    camera.updateProjectionMatrix();
  };

  let angle = 0.9;
  const frame = () => {
    camera.position.set(Math.cos(angle) * radius, Math.sin(angle) * radius, radius * 0.55);
    camera.lookAt(target);
    renderer.render(scene, camera);
  };

  new ResizeObserver(() => {
    resize();
    frame();
  }).observe(canvas);
  resize();
  frame();

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  if (reduceMotion.matches) return;

  let last = performance.now();
  const tick = (now: number) => {
    angle += ((now - last) / 1000) * 0.18;
    last = now;
    frame();
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
}
