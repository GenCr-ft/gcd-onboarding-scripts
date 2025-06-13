// Gencraft Standard commitlint.config.js (v1.2 - Approved)
// SSoT: devops-standards/tooling/configs/commitlint.config.js
// This configuration enforces Gencraft's Conventional Commits standard (TOOL_001_Conventional_Commits_Standard.md).
// It should be placed at the root of each repository using commitlint (typically via pre-commit).
// See [https://commitlint.js.org/#/reference-rules](https://commitlint.js.org/#/reference-rules) for all rule options.

module.exports = {
  // Extend from the conventional config, which provides good defaults based on Angular's convention.
  extends: ['@commitlint/config-conventional'],

  // Define Gencraft specific rules or override defaults here.
  // Rule configuration: [Level, Applicable, Value]
  // Level: 0-disable, 1-warning, 2-error
  // Applicable: "always" | "never"
  // Value: Varies per rule (string, number, array, etc.)

  rules: {
    // --- Type ---
    // Types allowed MUST be strictly aligned with TOOL_001_Conventional_Commits_Standard.md.
    // An AI Gem (Édouard or Camille) can be prompted to sync this list with TOOL_001.
    'type-enum': [
      2, // Level: Error - The commit will be rejected if the type is not in this list.
      'always', // Applicable: The type must always be one of the values in the array.
      [ // Value: Allowed types. Descriptions are for human reference.
        'feat',       // A new feature
        'fix',        // A bug fix
        'docs',       // Documentation only changes
        'style',      // Changes that do not affect the meaning of the code (white-space, formatting, etc)
        'refactor',   // A code change that neither fixes a bug nor adds a feature
        'perf',       // A code change that improves performance
        'test',       // Adding missing tests or correcting existing tests
        'build',      // Changes that affect the build system or external dependencies
        'ci',         // Changes to our CI configuration files and scripts
        'chore',      // Other changes that don't modify src or test files
        'revert',     // Reverts a previous commit
      ],
    ],

    // --- Subject ---
    // Enforce that the subject is not empty.
    'subject-empty': [2, 'never'],
    // Enforce that the subject does not end with a period.
    'subject-full-stop': [2, 'never', '.'],
    // Warn if the subject exceeds 72 characters.
    // 'subject-max-length': [
    //   1, // Level: Warning - Discourage overly long subjects.
    //   'always',
    //   72  // Max length. TOOL_001 recommends a soft limit of 50 and a hard limit of 72.
    //       // This provides a warning at 72. Strive for 50.
    // ],

    // --- Header (Type, Scope, Subject) ---
    // Max length for the entire header line (e.g., "feat(scope): subject").
    'header-max-length': [2, 'always', 100], // Hard limit for the header line.

    // --- Body ---
    // The body provides additional contextual information about the code changes.
    'body-leading-blank': [
      1, // Level: Warning - A blank line between subject and body improves readability.
      'always'
    ],
    'body-max-line-length': [
      1, // Level: Warning - Encourage wrapping body lines for readability.
      'always',
      100
    ],

    // --- Footer ---
    // Footer is used for metadata like "BREAKING CHANGE:" or "Refs: #ISSUE-ID".
    'footer-leading-blank': [
      1, // Level: Warning - A blank line between body and footer improves readability.
      'always'
    ],
    'footer-max-line-length': [
      1, // Level: Warning - Encourage wrapping footer lines.
      'always',
      100
    ],

    // --- Signed-off-by (Gencraft does not use DCO/signed-off-by) ---
    'signed-off-by': [0, 'always', 'Signed-off-by:'], // Disabled
  },
};
