# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2025-09-18

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-infrastructure-elements/compare/0.2.0...0.3.0)

- Add Kyverno firewall into a single object variable `kyverno_firewall_rule`; resource is now parameterized and conditional. `ports` accepts string values/ranges (e.g. "9443" or "9443-9445").

## [0.2.0] - 2025-04-18

[Compare with previous version](https://github.com/sparkfabrik/terraform-google-gcp-infrastructure-elements/compare/0.1.0...0.2.0)

- Add restricted tls 1.2 ssl policy

## [0.1.0] - 2025-03-19

- First release.
