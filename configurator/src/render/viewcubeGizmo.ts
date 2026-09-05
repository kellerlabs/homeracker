import {
  BufferGeometry,
  CanvasTexture,
  Color,
  Float32BufferAttribute,
  Mesh,
  MeshBasicMaterial,
  OrthographicCamera,
  Raycaster,
  Scene,
  SRGBColorSpace,
  Vector2,
  Vector3,
  type PerspectiveCamera,
  type WebGLRenderer,
} from "three";
import { HR_CHARCOAL, HR_WHITE, HR_YELLOW } from "../engine/constants";
import { cameraPositionFor, FACE_LABEL, gizmoBox, gizmoNdc, type CubeZone } from "./viewcube";
import { chamferedCube } from "./viewcubeGeometry";

const TEXTURE_PX = 128;
const HALF = 0.5;
/** How far the cut reaches back from each corner: enough to click, small enough to keep the label. */
const CHAMFER = 0.22;
/** Leaves the cube reading as a small badge in the corner rather than filling its box. */
const FRUSTUM = 0.95;
const CAMERA_DISTANCE = 4;

/** The cut corners sit a shade lighter than the faces, so the chamfer reads as a bevel. */
const CORNER_COLOR = new Color(HR_CHARCOAL).lerp(new Color(HR_WHITE), 0.22);

/** A face label drawn to a texture: `ink` on `paper`, with a border so the edges read at this size. */
function faceTexture(label: string, paper: string, ink: string): CanvasTexture {
  const canvas = document.createElement("canvas");
  canvas.width = TEXTURE_PX;
  canvas.height = TEXTURE_PX;
  const ctx = canvas.getContext("2d")!;
  ctx.fillStyle = paper;
  ctx.fillRect(0, 0, TEXTURE_PX, TEXTURE_PX);
  ctx.strokeStyle = ink;
  ctx.lineWidth = 4;
  ctx.strokeRect(2, 2, TEXTURE_PX - 4, TEXTURE_PX - 4);
  ctx.fillStyle = ink;
  // Fit the word between the cut corners: TOP gets to be large, BOTTOM shrinks until it still fits.
  const font = (px: number) => `600 ${px}px "Source Code Pro", ui-monospace, monospace`;
  let px = Math.round(TEXTURE_PX * 0.24);
  ctx.font = font(px);
  while (px > 8 && ctx.measureText(label).width > TEXTURE_PX * 0.72) {
    px -= 1;
    ctx.font = font(px);
  }
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(label, TEXTURE_PX / 2, TEXTURE_PX / 2);
  const texture = new CanvasTexture(canvas);
  // Without this the charcoal is treated as linear and washes out to mid grey.
  texture.colorSpace = SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
}

export interface ViewCube {
  /** Draw the cube in the corner of `renderer`, turned to match `camera` looking at `target`. */
  draw(renderer: WebGLRenderer, camera: PerspectiveCamera, target: Vector3): void;
  /** The zone under a pointer at css pixels `px`, `py` on a canvas `width` wide; null when outside. */
  hitTest(px: number, py: number, width: number): CubeZone | null;
  /** Light up one facet; returns true when that changed anything, so the caller knows to redraw. */
  setHovered(zone: CubeZone | null): boolean;
  /** Where the camera should stand to look at `target` from `zone`, keeping its distance. */
  positionFor(zone: CubeZone, target: Vector3, distance: number): Vector3;
}

export function createViewCube(): ViewCube {
  const facets = chamferedCube(HALF, CHAMFER);
  const geometry = new BufferGeometry();
  const positions: number[] = [];
  const uvs: number[] = [];
  facets.forEach((facet, i) => {
    geometry.addGroup(positions.length / 3, facet.positions.length / 3, i);
    positions.push(...facet.positions);
    uvs.push(...facet.uvs);
  });
  geometry.setAttribute("position", new Float32BufferAttribute(positions, 3));
  geometry.setAttribute("uv", new Float32BufferAttribute(uvs, 2));

  const skin = (paper: string, ink: string) =>
    facets.map((f) =>
      f.labelled
        ? new MeshBasicMaterial({ map: faceTexture(FACE_LABEL[f.faces[0]!], paper, ink) })
        : new MeshBasicMaterial({ color: paper === HR_CHARCOAL ? CORNER_COLOR : new Color(HR_YELLOW) }),
    );
  const rest = skin(HR_CHARCOAL, HR_WHITE);
  const lit = skin(HR_YELLOW, HR_CHARCOAL);
  const materials = facets.map((_, i) => rest[i]!.clone());
  const cube = new Mesh(geometry, materials);

  const scene = new Scene();
  scene.add(cube);
  const camera = new OrthographicCamera(-FRUSTUM, FRUSTUM, FRUSTUM, -FRUSTUM, 0.1, 10);
  const raycaster = new Raycaster();
  const size = new Vector2();
  let hovered = -1;

  const paint = (prev: number) => {
    if (prev >= 0 && prev !== hovered) {
      materials[prev]!.copy(rest[prev]!);
      materials[prev]!.needsUpdate = true;
    }
    if (hovered >= 0) {
      materials[hovered]!.copy(lit[hovered]!);
      materials[hovered]!.needsUpdate = true;
    }
  };

  return {
    draw(renderer, mainCamera, target) {
      renderer.getSize(size);
      const box = gizmoBox(size.x);
      // A gl viewport counts from the bottom left; the gizmo is placed from the top.
      const bottom = size.y - box.y - box.size;
      camera.position.copy(mainCamera.position).sub(target).normalize().multiplyScalar(CAMERA_DISTANCE);
      camera.up.copy(mainCamera.up);
      camera.lookAt(0, 0, 0);

      const autoClear = renderer.autoClear;
      renderer.autoClear = false;
      renderer.setViewport(box.x, bottom, box.size, box.size);
      renderer.setScissor(box.x, bottom, box.size, box.size);
      renderer.setScissorTest(true);
      renderer.clearDepth();
      renderer.render(scene, camera);
      renderer.setScissorTest(false);
      renderer.setViewport(0, 0, size.x, size.y);
      renderer.autoClear = autoClear;
    },

    hitTest(px, py, width) {
      const ndc = gizmoNdc(gizmoBox(width), px, py);
      if (!ndc) return null;
      raycaster.setFromCamera(new Vector2(ndc[0], ndc[1]), camera);
      const hit = raycaster.intersectObject(cube, false)[0];
      const index = hit?.face?.materialIndex;
      return index === undefined ? null : (facets[index] ?? null);
    },

    setHovered(zone) {
      const index = zone ? facets.findIndex((f) => f.id === zone.id) : -1;
      if (hovered === index) return false;
      const prev = hovered;
      hovered = index;
      paint(prev);
      return true;
    },

    positionFor(zone, target, distance) {
      const [x, y, z] = cameraPositionFor(zone.direction, [target.x, target.y, target.z], distance);
      return new Vector3(x, y, z);
    },
  };
}
