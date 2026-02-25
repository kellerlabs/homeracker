// HomeRacker - Core Constants
//
// Shared constants and measurements for the HomeRacker - Core system.
// Include this file in all core components to ensure consistency.
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

// Prevent OpenSCAD Z-fighting in peview
EPSILON = $preview ? 0.01 : 0.00001;

// Fitting tolerance between mating parts
TOLERANCE = 0.2; // in mm

// Default 3D printing parameters
PRINTING_LAYER_WIDTH = 0.4; // in mm
PRINTING_LAYER_HEIGHT = 0.2; // in mm

// HomeRacker base measurements
BASE_UNIT = 15; // Base unit for all core measurements in mm
BASE_STRENGTH = 2; // Wall thickness in mm
BASE_CHAMFER = 1; // Chamfer size in mm

// Lock pin hole dimensions
LOCKPIN_HOLE_CHAMFER = 0.8; // Chamfer size in mm
LOCKPIN_HOLE_SIDE_LENGTH = 4; // Square hole side length in mm
LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION = [LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH];

// HomeRacker Colors
HR_YELLOW = "#f7b600";
HR_BLUE = "#0056b3";
HR_RED = "#c41e3a";
HR_GREEN = "#2d7a2e";
HR_CHARCOAL = "#333333";
HR_WHITE = "#f0f0f0";

// Standard rackmount measurements
STD_UNIT_HEIGHT = 44.45;  // Height of one rack unit (1U = 44.45mm)
STD_UNIT_DEPTH = 482.6;   // Standard rackmount depth (19" = 482.6mm)
STD_WIDTH_10INCH = 254;   // 10" width in mm
STD_WIDTH_19INCH = 482.6; // 19" width in mm
STD_MOUNT_SURFACE_WIDTH = 15.875; // Mounting surface width in mm

STD_RACK_BORE_DISTANCE_Z = 15.875;          // Vertical distance between mounting holes in mm
STD_RACK_BORE_DISTANCE_MARGIN_Z = 6.35;     // Top/bottom margin to first/last mounting hole in mm

// DEPRECATED: Legacy lowercase constants (will be removed in future versions)
// Use uppercase constants above instead
tolerance = TOLERANCE;
printing_layer_width = PRINTING_LAYER_WIDTH;
printing_layer_height = PRINTING_LAYER_HEIGHT;
base_unit = BASE_UNIT;
base_strength = BASE_STRENGTH;
base_chamfer = BASE_CHAMFER;
lockpin_hole_chamfer = LOCKPIN_HOLE_CHAMFER;
lockpin_hole_side_length = LOCKPIN_HOLE_SIDE_LENGTH;
lockpin_hole_side_length_dimension = LOCKPIN_HOLE_SIDE_LENGTH_DIMENSION;
