# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  # Warn-only for now (docs/plans/own-the-tokens.md Phase 2) — becomes a `step` (and
  # therefore fails CI) once Phase 3 replaces the last vendored Optics components.
  # Components should spend --gp-* roles, not a raw ramp step or an --op-* token. A
  # component-private `--_gp-*` token is allowed to read the ramp directly (that's the
  # documented escape hatch), so those declarations don't count as violations.
  tier_violations = `grep -rn -- '--gp-n-\\|--op-color-' app/assets/stylesheets/components/ app/views/`
    .each_line.reject { |line| line.match?(/--_gp-[\w-]+:\s*var\(--gp-n-/) }.join
  unless tier_violations.strip.empty?
    puts "\nWARN: raw ramp/Optics-color tokens outside the roles layer:\n#{tier_violations}"
  end

  step "Security: Gem audit", "bin/bundler-audit"
  # Production deps only — devDependencies is the webpack build chain, whose
  # transitive advisories we don't ship. Mirrors the scan_js job in ci.yml.
  step "Security: JS dependency audit", "yarn audit --level high --groups dependencies"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests", "bundle exec rspec"


  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
