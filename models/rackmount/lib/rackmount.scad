// HomeRacker - Rackmount Adapter
//
// Customizable Rackmount adapter for the HomeRacker system.
// Designed to fit standard 10/19-inch rack systems, commonly used in server and audio equipment.
//
// MIT License
// Copyright (c) 2025 Patrick Pötz
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

include <BOSL2/std.scad>
include <../../core/lib/constants.scad>


/* [Hidden] */
$fn=100;
// rackmount constants
// FYI: this first iteration just assumes M6 cage nuts and bolts.

// Cage Nut Hole constants (taken from the original Fusion360 design)
hr_rackmount_cage_nut_hole_height = 9.5; // in mm

// the front part of the cage nut hole
hr_rackmount_cage_nut_hole_front_height = 8.5; // in mm - a bit smaller than the total height for more "flesh" at the front
hr_rackmount_cage_nut_hole_front_width = 6.5; // in mm
hr_rackmount_cage_nut_hole_front_depth = 2; // in mm
hr_rackmount_cage_nut_hole_front_rounding = 3; // in mm - radius of a M6 screw thread

// the part where the hooks of the cage nut engage
hr_rackmount_cage_nut_hole_mid_width = 13.4; // in mm - hooks of a cage nut are 14mm
hr_rackmount_cage_nut_hole_mid_depth = 0.6; // in mm

// the rackside hook part of the cage nut hole
// formed as cylinders left and right at the back of the hole
hr_rackmount_cage_nut_hole_back_radius = 1.5; // in mm
hr_rackmount_cage_nut_hole_back_width = 12.5; // in mm


/**
 * Returns the total depth of the rackmount cage nut hole.
 * Required for calling panels that need to know their own required depth to place the cage nut hole correctly.
 */
function get_rackmount_cage_nut_hole_depth() =
  hr_rackmount_cage_nut_hole_front_depth
  + hr_rackmount_cage_nut_hole_mid_depth
  + hr_rackmount_cage_nut_hole_back_radius*2;

/**
 * Rackmount Cage Nut Hole Module
 * Represents the negative to be cutout from a rackmount panel.
 */
module rackmount_cage_nut_hole(anchor=CENTER, orient=UP, spin=0) {

    module rackmount_cage_nut_hole_front(anchor=CENTER, orient=UP, spin=0) {
      attachable(size=[hr_rackmount_cage_nut_hole_front_width, hr_rackmount_cage_nut_hole_front_depth, hr_rackmount_cage_nut_hole_front_height], anchor=anchor, orient=orient, spin=spin){
        color(HR_YELLOW)
        cuboid(
          [hr_rackmount_cage_nut_hole_front_width, hr_rackmount_cage_nut_hole_front_depth, hr_rackmount_cage_nut_hole_front_height],
          rounding=hr_rackmount_cage_nut_hole_front_rounding,except=[FRONT,BACK]
          );
        children();
      }
    }

    module rackmount_cage_nut_hole_mid(anchor=CENTER, orient=UP, spin=0) {
      attachable(size=[hr_rackmount_cage_nut_hole_mid_width, hr_rackmount_cage_nut_hole_mid_depth, hr_rackmount_cage_nut_hole_height], anchor=anchor, orient=orient, spin=spin){
        color(HR_GREEN)
        cuboid([hr_rackmount_cage_nut_hole_mid_width, hr_rackmount_cage_nut_hole_mid_depth, hr_rackmount_cage_nut_hole_height]);
        children();
      }
    }

    module rackmount_cage_nut_hole_back(anchor=CENTER, orient=UP, spin=0) {
      attachable(size=[hr_rackmount_cage_nut_hole_back_width, hr_rackmount_cage_nut_hole_back_radius*2, hr_rackmount_cage_nut_hole_height], anchor=anchor, orient=orient, spin=spin){
        color_this(HR_BLUE)
        diff()
        cuboid([hr_rackmount_cage_nut_hole_back_width, hr_rackmount_cage_nut_hole_back_radius*2, hr_rackmount_cage_nut_hole_height]){
          align([LEFT,RIGHT],inside=true,overlap=hr_rackmount_cage_nut_hole_back_radius)
          color(HR_RED)
          cylinder(r=hr_rackmount_cage_nut_hole_back_radius, h=hr_rackmount_cage_nut_hole_height+HR_EPSILON);
        }
        children();
      }
    }

    attachable_width = hr_rackmount_cage_nut_hole_mid_width;
    attachable_depth = get_rackmount_cage_nut_hole_depth();
    attachable_height = hr_rackmount_cage_nut_hole_height;

    attachable(size=[attachable_width, attachable_depth, attachable_height], anchor=CENTER, orient=UP, spin=0){
      fwd(hr_rackmount_cage_nut_hole_mid_depth/2+hr_rackmount_cage_nut_hole_back_radius)
      rackmount_cage_nut_hole_front(){
        attach(BACK,FRONT) rackmount_cage_nut_hole_mid(){
          attach(BACK,FRONT) rackmount_cage_nut_hole_back();
        }
      }
      children();
    }



}

//cylinder(r=hr_rackmount_cage_nut_hole_back_radius, h=hr_rackmount_cage_nut_hole_height);


rackmount_cage_nut_hole();
