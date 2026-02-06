// Sprockets manifest that tells Rails which assets should be included in the precompiled asset pipeline.
// the = makes it a Sprockets directive. These are not ignored — Sprockets parses them at build time.

//= link_tree ../images
//= link_tree ../../javascript .js
//= link_tree ../../../vendor/javascript .js


//= link popper.js
//= link bootstrap.min.js

//= link_tree ../builds
//= link shadcn/index.js
