// HomeRacker - Print Bed Fit
//
// Calculates the longest part of a given width that fits on a print bed, including diagonal placement.
// Generic: nothing here is HomeRacker-specific, and the library may move to its own repository.
// Results use the pure usable bed area without any safety margin for brims, skirts or bed exclusion zones.
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

// Usable bed area [x, y] in mm per printer, from the printers' OrcaSlicer profiles (printable_area).
// Full-length edge strips in bed_exclude_area are subtracted; corner exclusions are not.
// Dual-nozzle printers list the area both nozzles reach; the *_single keys list the left nozzle's area.
PRINT_BEDS = [
  // Bambu Lab
  ["bambu_a1_mini", [180, 180]],
  ["bambu_a1", [256, 256]],
  ["bambu_a2l", [330, 320]],
  ["bambu_p1p", [256, 256]],
  ["bambu_p1s", [256, 256]],
  ["bambu_p2s", [256, 256]],
  ["bambu_x1", [256, 256]],
  ["bambu_x1c", [256, 256]],
  ["bambu_x1e", [256, 256]],
  ["bambu_x2d", [235.5, 256]],
  ["bambu_x2d_single", [256, 256]],
  ["bambu_h2s", [340, 320]],
  ["bambu_h2d", [300, 320]],
  ["bambu_h2d_single", [325, 320]],
  ["bambu_h2d_pro", [300, 320]],
  ["bambu_h2d_pro_single", [325, 320]],
  ["bambu_h2c", [300, 320]],
  ["bambu_h2c_single", [325, 320]],
  // Prusa
  ["prusa_mini", [180, 180]],
  ["prusa_mk3s", [250, 210]],
  ["prusa_mk4", [250, 210]],
  ["prusa_mk4s", [250, 210]],
  ["prusa_core_one", [250, 220]],
  ["prusa_core_one_l", [300, 300]],
  ["prusa_xl", [360, 360]],
  // Creality
  ["creality_ender3_v3", [220, 220]],
  ["creality_ender3_v3_ke", [220, 220]],
  ["creality_ender3_v3_se", [220, 220]],
  ["creality_ender3_v3_plus", [300, 300]],
  ["creality_hi", [260, 260]],
  ["creality_k1", [220, 220]],
  ["creality_k1c", [220, 220]],
  ["creality_k1_max", [300, 300]],
  ["creality_k2", [260, 260]],
  ["creality_k2_pro", [300, 300]],
  ["creality_k2_plus", [350, 350]],
  // Elegoo
  ["elegoo_centauri_carbon", [256, 256]],
  ["elegoo_centauri_carbon_2", [256, 256]],
  // Anycubic
  ["anycubic_kobra_3", [251, 251]],
  ["anycubic_kobra_3_max", [420, 420]],
  ["anycubic_kobra_s1", [250, 250]],
  ["anycubic_kobra_s1_max", [350, 350]],
  // Qidi
  ["qidi_q1_pro", [245, 245]],
  ["qidi_q2", [270, 270]],
  ["qidi_x_max_3", [325, 325]],
  // Sovol
  ["sovol_sv08", [350, 350]],
  ["sovol_sv08_max", [500, 500]],
  // Snapmaker
  ["snapmaker_u1", [270, 270]],
  // Voron
  ["voron_2_4_250", [250, 250]],
  ["voron_2_4_300", [300, 300]],
  ["voron_2_4_350", [350, 350]],
];

/**
 * Returns the usable bed area [x, y] in mm of a printer key from PRINT_BEDS.
 */
function bed_size(printer) =
  let(_idx = search([printer], PRINT_BEDS)[0])
  assert(_idx != [], str("Unknown printer: ", printer))
  PRINT_BEDS[_idx][1];

/**
 * Returns [length, angle] of the longest part of the given width that fits on the bed.
 * The angle is the part's long axis in degrees from the bed's X axis (0 = along X, 90 = along Y).
 * Returns [0, undef] when no orientation fits.
 */
function print_fit(bed, width) =
  let(
    _lo = width > bed[1] ? acos(bed[1] / width) : 0,
    _hi = width > bed[0] ? asin(bed[0] / width) : 90
  )
  _lo > _hi ? [0, undef]
  : let(
    _steps = 360,
    _step = (_hi - _lo) / _steps,
    _samples = [for (i = [0:_steps])[_fit_length(bed, width, _lo + i * _step), _lo + i * _step]],
    _best = _max_by_length(_samples)
  )
  _best[0] <= 0 ? [0, undef]
  : let(
    _refined = _refine_angle(bed, width, max(_lo, _best[1] - _step), min(_hi, _best[1] + _step), 60),
    _candidate = [_fit_length(bed, width, _refined), _refined]
  )
  _candidate[0] > _best[0] ? _candidate : _best;

/**
 * Returns the length of the longest part of the given width that fits on the bed.
 */
function max_print_length(bed, width) = print_fit(bed, width)[0];

/**
 * Returns the angle in degrees at which a part of the given width and length fits on the bed, or undef if it does not.
 * Prefers straight placement: 0 along X, then 90 along Y, then the diagonal angle of print_fit.
 */
function print_angle(bed, width, length) =
  let(
    _short = min(width, length),
    _long = max(width, length),
    _fit = print_fit(bed, _short)
  )
  _long <= bed[0] && _short <= bed[1] ? 0
  : _long <= bed[1] && _short <= bed[0] ? 90
  : _long <= _fit[0] ? _fit[1]
  : undef;

// Longest part at a fixed angle: its bounding box must stay within the bed. -1 if the width alone overflows.
function _fit_length(bed, width, angle) =
  let(
    _c = cos(angle),
    _s = sin(angle),
    _room_x = bed[0] - width * _s,
    _room_y = bed[1] - width * _c
  )
  _room_x < -1e-9 || _room_y < -1e-9 ? -1
  : min(_c > 1e-9 ? max(0, _room_x) / _c : 1e9, _s > 1e-9 ? max(0, _room_y) / _s : 1e9);

function _max_by_length(samples, i = 0, best = [-1, undef]) =
  i >= len(samples) ? best
  : _max_by_length(samples, i + 1, samples[i][0] > best[0] ? samples[i] : best);

// Ternary search for the best angle within [lo, hi], where the fit length is unimodal.
function _refine_angle(bed, width, lo, hi, iterations) =
  iterations <= 0 ? (lo + hi) / 2
  : let(
    _m1 = lo + (hi - lo) / 3,
    _m2 = hi - (hi - lo) / 3
  )
  _fit_length(bed, width, _m1) < _fit_length(bed, width, _m2)
  ? _refine_angle(bed, width, _m1, hi, iterations - 1)
  : _refine_angle(bed, width, lo, _m2, iterations - 1);
