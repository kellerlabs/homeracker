# Core Tests

This directory contains test files for the HomeRacker core system.

## Purpose

Test files in this directory are automatically discovered and validated by the test suite:
```bash
./cmd/test/test-models.sh
```

## Test Files

- **`connector.scad`**: Tests the connector module with default parameters
- **`support.scad`**: Tests the support module with default parameters

## Adding Tests

To add a new test:
1. Create a `.scad` file in this directory
2. Include the core library: `include <../main.scad>`
3. Render a specific test case with chosen parameters
4. Run `./cmd/test/test-models.sh` to validate

Each test file should produce a valid, renderable 3D object.
