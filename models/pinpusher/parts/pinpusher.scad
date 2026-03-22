// HomeRacker - Lockpin Pusher
//
// A simple tool to push lockpins out of connectors.
// The shaft fits through lockpin holes; the grip provides
// a pinch surface for thumb and index finger.
//
// This model is part of the HomeRacker - Utility system.
//
// MIT License
// Copyright (c) 2026 Patrick Pötz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Note: this is just a makeshift solution. Not 100% happy with it but it'll do for now.

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>

/* [Hidden] */
$fn = 100;

pusher_length =
    BASE_UNIT + BASE_STRENGTH * 2 + TOLERANCE;
pusher_side =
    LOCKPIN_HOLE_SIDE_LENGTH - TOLERANCE;

grip_width =
    BASE_UNIT/2;
grip_mid_width =
    grip_width - BASE_STRENGTH;
grip_depth =
    BASE_UNIT / 2;

/**
 * 📐 pinpusher module
 *
 * Creates a lockpin pusher tool for the HomeRacker system.
 * Lies flat for optimal printing. Shaft pushes lockpins out of connectors.
 * Prismoid grip for pinching between thumb and index finger.
 */
module pinpusher() {
  color(HR_YELLOW)
  xrot(90)
  prismoid(
    size1 = [grip_width, grip_width],
    size2 = [grip_mid_width, grip_mid_width],
    h = grip_depth,
    shift = [0, -BASE_STRENGTH/2],
    chamfer = BASE_CHAMFER
  )
  attach(TOP, BOTTOM)
  prismoid(
    size1 = [grip_mid_width, grip_mid_width],
    size2 = [grip_width, grip_width],
    shift = [0, BASE_STRENGTH/2],
    h = grip_depth,
    chamfer = BASE_CHAMFER
  )
  align(TOP, FRONT)
  cuboid(
    [pusher_side, pusher_side, pusher_length],
    chamfer = BASE_CHAMFER,
    edges = [LEFT,RIGHT],
    except = [BOTTOM,TOP]
  );
}

pinpusher();
