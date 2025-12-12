# Project Instructions

## ⚠️ CONVERSION REQUIRED: TypeScript/JavaScript → ReScript

This repository needs FULL conversion from TS/JS to ReScript.

### Policy (RSR)
- **REQUIRED**: ReScript for all code
- **FORBIDDEN**: TypeScript (.ts, .tsx)
- **FORBIDDEN**: JavaScript (.js, .jsx) except generated .res.js
- **EXCEPTION**: WASM for performance-critical computation

### When modifying this codebase:
1. DO NOT add new TS/JS files
2. When touching existing TS/JS, convert to ReScript
3. Create `.res` file with equivalent logic
4. Delete the original TS/JS file
5. Run `rescript build` to generate JS

### DO NOT:
- Add new TypeScript files
- Write raw JavaScript
- Use tsc or TypeScript compiler

See TS_CONVERSION_NEEDED.md for full migration guide.
