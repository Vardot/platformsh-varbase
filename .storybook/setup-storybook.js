#!/usr/bin/env node

function setupStorybook() {
  const platformShConfig = require("platformsh-config").config();

  // Get the platform environment Storybook CL server domain to serve the Storybook.
  return platformShConfig.getPrimaryRoute()['url'];
}

process.stdout.write(setupStorybook());
