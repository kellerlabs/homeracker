import { describe, expect, test } from "vitest";
import { parseCatalog } from "../src/lib/catalog";

const body = `# 📦 Models

Intro text.

## 📑 Contents

### 🧱 Core

The fundamental HomeRacker building system with modular components:

- **Supports**: Vertical and horizontal structural elements

![Connector](./core/parts/renders/connector.png)

See [core/README.md](core/README.md) for details.

### Flexmount (⚠️ Deprecated)

Universal device mount — deprecated in favor of something else.

See [flexmount/README.md](flexmount/README.md) for details.

## 📁 Standard Model Structure

Ignore this.
`;

describe("parseCatalog", () => {
  test("returns one card per model in document order", () => {
    const cards = parseCatalog(body);
    expect(cards.map((c) => c.slug)).toEqual(["core", "flexmount"]);
  });

  test("extracts title, description and first render image", () => {
    const [core] = parseCatalog(body);
    expect(core).toEqual({
      slug: "core",
      title: "🧱 Core",
      description: "The fundamental HomeRacker building system with modular components:",
      image: "core/parts/renders/connector.png",
      deprecated: false,
    });
  });

  test("flags deprecated models and tolerates missing images", () => {
    const [, flex] = parseCatalog(body);
    expect(flex?.deprecated).toBe(true);
    expect(flex?.image).toBeNull();
  });
});
